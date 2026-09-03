import Foundation

/// Último snapshot recebido do Mac, persistido no App Group para
/// que o widget e a extensão de configuração leiam os mesmos dados.
struct ProcessSnapshot: Codable, Equatable {
    var processes: [RemoteProcess]
    var serverName: String
    var updatedAt: Date
}

/// Persistência compartilhada entre o app Companion e o ProcessWidget
/// via App Group (`group.dev.smartium.Companion`).
enum ProcessSnapshotStore {

    static let appGroupID = "group.dev.smartium.Companion"

    private static let snapshotKey = "latestProcessSnapshot.v1"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func save(_ snapshot: ProcessSnapshot) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            defaults?.set(data, forKey: snapshotKey)
        } catch {
            print("[SnapshotStore] ❌ Falha ao codificar snapshot: \(error)")
        }
    }

    static func load() -> ProcessSnapshot? {
        guard let data = defaults?.data(forKey: snapshotKey) else { return nil }
        do {
            return try JSONDecoder().decode(ProcessSnapshot.self, from: data)
        } catch {
            print("[SnapshotStore] ❌ Falha ao decodificar snapshot: \(error)")
            return nil
        }
    }
}
