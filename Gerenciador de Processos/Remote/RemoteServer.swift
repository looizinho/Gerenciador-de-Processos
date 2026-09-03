import Foundation
import Network

/// Servidor TCP com anúncio Bonjour que expõe a lista de processos
/// gerenciados para o app Companion (iOS) na rede local.
///
/// Protocolo: NDJSON — cada atualização é uma linha JSON (`RemoteMessage`).
/// Sem autenticação por ora — apenas leitura em rede local.
final class RemoteServer {

    static let serviceType = "_gerproc._tcp"

    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private let queue = DispatchQueue(label: "dev.smartium.gerenciador.remoteserver")
    private let encoder = JSONEncoder()

    /// Última mensagem enviada — reenviada a cada nova conexão.
    private var lastMessage: Data?

    // MARK: - Listener

    func start() {
        guard listener == nil else { return }

        do {
            let parameters = NWParameters.tcp
            let listener = try NWListener(using: parameters)
            listener.service = NWListener.Service(name: Host.current().localizedName, type: Self.serviceType, domain: nil)

            listener.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("[RemoteServer] ✅ Ouvindo na porta \(listener.port?.rawValue ?? 0), serviço \(Self.serviceType)")
                case .failed(let error):
                    print("[RemoteServer] ❌ Listener falhou: \(error)")
                case .cancelled:
                    print("[RemoteServer] Listener cancelado")
                default:
                    break
                }
                _ = self
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.accept(connection)
            }

            listener.start(queue: queue)
            self.listener = listener
        } catch {
            print("[RemoteServer] ❌ Falha ao criar listener: \(error)")
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    // MARK: - Conexões

    private func accept(_ connection: NWConnection) {
        connection.stateUpdateHandler = { [weak self, weak connection] state in
            guard let self, let connection else { return }
            switch state {
            case .ready:
                print("[RemoteServer] Cliente conectado: \(connection.endpoint)")
                if let lastMessage = self.lastMessage {
                    self.send(lastMessage, to: connection)
                }
            case .failed(let error):
                print("[RemoteServer] Conexão falhou: \(error)")
                self.remove(connection)
            case .cancelled:
                self.remove(connection)
            default:
                break
            }
        }

        // Precisamos consumir dados para detectar fechamento remoto, mesmo
        // que o cliente não envie nada nesta versão.
        receiveLoop(on: connection)

        connection.start(queue: queue)
        connections.append(connection)
    }

    private func remove(_ connection: NWConnection) {
        connections.removeAll { $0 === connection }
        connection.cancel()
    }

    private func receiveLoop(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self, weak connection] data, _, isComplete, error in
            guard let self, let connection else { return }
            // Versão atual ignora o conteúdo recebido (somente leitura).
            if isComplete || error != nil {
                self.remove(connection)
                return
            }
            self.receiveLoop(on: connection)
        }
    }

    // MARK: - Broadcast

    /// Publica a lista atual de processos para todos os clientes conectados.
    /// Pode ser chamada de qualquer thread.
    func publish(processes: [ManagedProcess]) {
        let message = RemoteMessage.snapshot(of: processes)
        guard var data = try? encoder.encode(message) else { return }
        data.append(0x0A) // \n — delimitador NDJSON

        queue.async { [weak self] in
            guard let self else { return }
            self.lastMessage = data
            self.connections.forEach { self.send(data, to: $0) }
        }
    }

    private func send(_ data: Data, to connection: NWConnection) {
        connection.send(content: data, completion: .contentProcessed { [weak self, weak connection] error in
            if let error {
                print("[RemoteServer] Erro ao enviar: \(error)")
                if let connection { self?.remove(connection) }
            }
        })
    }
}
