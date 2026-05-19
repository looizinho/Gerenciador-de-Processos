import Foundation

class PersistenceService {
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let folder = appSupport.appendingPathComponent("GerenciadorDeProcessos", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("processes.json")
    }

    func save(_ processes: [ManagedProcess]) {
        guard let data = try? JSONEncoder().encode(processes) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func load() -> [ManagedProcess] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let processes = try? JSONDecoder().decode([ManagedProcess].self, from: data)
        else { return [] }
        return processes
    }
}
