import Foundation

/// Processo gerenciado recebido do app macOS (Gerenciador de Processos).
/// Espelho do `RemoteProcess` definido no lado do servidor.
struct RemoteProcess: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var command: String
    var status: String   // "running" | "stopped"
    var pid: Int32?

    var isRunning: Bool { status == "running" }
}

/// Mensagem enviada pelo servidor (macOS) — protocolo NDJSON
/// (uma mensagem JSON por linha).
struct RemoteMessage: Codable {
    var type: String            // "snapshot"
    var processes: [RemoteProcess]
}
