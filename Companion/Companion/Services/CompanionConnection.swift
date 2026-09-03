import Foundation
import Network
import Observation
import WidgetKit

/// Estado da conexão com o Gerenciador de Processos (macOS).
enum ConnectionState: Equatable {
    case idle
    case browsing
    case connecting(server: String)
    case connected(server: String)
    case waiting(message: String)
    case failed(message: String)
}

/// Descobre o Mac via Bonjour e mantém uma conexão TCP recebendo
/// snapshots da lista de processos (NDJSON, uma mensagem por linha).
@Observable
final class CompanionConnection {
    private(set) var state: ConnectionState = .idle
    private(set) var processes: [RemoteProcess] = []
    private(set) var lastUpdate: Date?

    static let serviceType = "_gerproc._tcp"

    private var browser: NWBrowser?
    private var connection: NWConnection?
    private var buffer = Data()
    private let decoder = JSONDecoder()
    private let queue = DispatchQueue(label: "dev.smartium.companion.connection")

    /// Endpoint do último servidor utilizado — usado para reconectar.
    private var lastEndpoint: NWEndpoint?
    private var scheduledRetry: DispatchWorkItem?

    // MARK: - Ciclo de vida

    func start() {
        queue.async { [weak self] in
            guard let self, self.browser == nil else { return }
            self.startBrowsing()
        }
    }

    func stop() {
        queue.async { [weak self] in
            guard let self else { return }
            self.scheduledRetry?.cancel()
            self.browser?.cancel()
            self.browser = nil
            self.connection?.cancel()
            self.connection = nil
            self.setState(.idle)
        }
    }

    // MARK: - Bonjour

    private func startBrowsing() {
        setState(.browsing)

        let descriptor = NWBrowser.Descriptor.bonjour(type: Self.serviceType, domain: nil)
        let browser = NWBrowser(for: descriptor, using: .tcp)

        browser.stateUpdateHandler = { [weak self] browserState in
            guard let self else { return }
            if case .failed(let error) = browserState {
                self.setState(.failed(message: "Busca falhou: \(error.localizedDescription)"))
            }
        }

        browser.browseResultsChangedHandler = { [weak self] results, _ in
            guard let self else { return }
            // Conecta no primeiro serviço encontrado (versão atual: um único Mac)
            if self.connection == nil, let result = results.first {
                self.connect(to: result.endpoint)
            }
        }

        browser.start(queue: queue)
        self.browser = browser
    }

    // MARK: - Conexão

    private func connect(to endpoint: NWEndpoint) {
        let connection = NWConnection(to: endpoint, using: .tcp)
        self.connection = connection
        lastEndpoint = endpoint

        let serverName: String
        if case .service(let name, _, _, _) = endpoint {
            serverName = name
        } else {
            serverName = "Mac"
        }
        setState(.connecting(server: serverName))

        connection.stateUpdateHandler = { [weak self, weak connection] connState in
            guard let self, let connection else { return }
            switch connState {
            case .ready:
                print("[Companion] ✅ Conectado a \(serverName)")
                self.setState(.connected(server: serverName))
                self.receiveLoop(on: connection)
            case .failed(let error):
                print("[Companion] ❌ Conexão falhou: \(error)")
                self.handleDisconnect(error.localizedDescription)
            case .waiting(let error):
                print("[Companion] Aguardando rede: \(error)")
                self.setState(.waiting(message: "Aguardando rede…"))
            case .cancelled:
                break
            default:
                break
            }
        }

        connection.start(queue: queue)
    }

    private func handleDisconnect(_ reason: String) {
        connection?.cancel()
        connection = nil
        buffer = Data()
        setState(.failed(message: reason))
        scheduleRetry()
    }

    private func scheduleRetry() {
        scheduledRetry?.cancel()
        guard let endpoint = lastEndpoint else { return }

        let retry = DispatchWorkItem { [weak self] in
            guard let self, self.connection == nil else { return }
            print("[Companion] Tentando reconectar…")
            self.connect(to: endpoint)
        }
        scheduledRetry = retry
        queue.asyncAfter(deadline: .now() + 3, execute: retry)
    }

    // MARK: - Recepção (NDJSON)

    private func receiveLoop(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 256 * 1024) { [weak self, weak connection] data, _, isComplete, error in
            guard let self, let connection else { return }

            if let data, !data.isEmpty {
                self.buffer.append(data)
                self.processBuffer()
            }

            if isComplete || error != nil {
                self.handleDisconnect(error?.localizedDescription ?? "Conexão encerrada")
                return
            }

            self.receiveLoop(on: connection)
        }
    }

    /// Extrai mensagens completas (terminadas em \n) do buffer acumulado.
    private func processBuffer() {
        while let newlineIndex = buffer.firstIndex(of: 0x0A) {
            let line = Data(buffer.prefix(upTo: newlineIndex))
            buffer = Data(buffer.suffix(from: buffer.index(after: newlineIndex)))

            if !line.isEmpty {
                decode(line: line)
            }
        }
    }

    private func decode(line: Data) {
        do {
            let message = try decoder.decode(RemoteMessage.self, from: line)
            guard message.type == "snapshot" else { return }
            let updated = message.processes
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.processes = updated
                self.lastUpdate = Date()
                self.persistSnapshot(updated)
                // Atualiza o ProcessWidget com o estado mais recente
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            print("[Companion] ❌ Falha ao decodificar mensagem: \(error)")
        }
    }

    /// Persiste o último snapshot no App Group para o ProcessWidget ler.
    private func persistSnapshot(_ processes: [RemoteProcess]) {
        let serverName: String
        if case .connected(let name) = state {
            serverName = name
        } else {
            serverName = "Mac"
        }
        ProcessSnapshotStore.save(
            ProcessSnapshot(processes: processes, serverName: serverName, updatedAt: Date())
        )
    }

    // MARK: - Estado publicado (sempre na main thread)

    private func setState(_ newState: ConnectionState) {
        DispatchQueue.main.async { [weak self] in
            self?.state = newState
        }
    }
}
