import Foundation

/// Foto de um processo gerenciado, enviada ao app Companion.
/// Espelho "somente leitura" de `ManagedProcess` para tráfego de rede.
struct RemoteProcess: Codable, Equatable {
    let id: UUID
    var name: String
    var command: String
    var status: String   // "running" | "stopped"
    var pid: Int32?

    nonisolated init(from process: ManagedProcess) {
        self.id = process.id
        self.name = process.name
        self.command = process.command
        self.status = process.status == .running ? "running" : "stopped"
        self.pid = process.pid
    }
}

/// Mensagem enviada pelo servidor (macOS) aos clientes (iOS) via TCP.
/// Uma mensagem por linha (NDJSON).
struct RemoteMessage: Codable, Equatable {
    var type: String            // "snapshot"
    var processes: [RemoteProcess]

    static func snapshot(of processes: [ManagedProcess]) -> RemoteMessage {
        RemoteMessage(type: "snapshot", processes: processes.map { RemoteProcess(from: $0) })
    }
}
