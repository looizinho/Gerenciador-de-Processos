import WidgetKit
import DeveloperToolsSupport

/// Uma "foto" do que o widget exibe em determinado momento.
struct ProcessWidgetEntry: TimelineEntry {
    let date: Date
    let process: RemoteProcess?
    let serverName: String?
    let updatedAt: Date?
}

/// Gera as entradas do widget a partir do snapshot persistido no App Group.
struct ProcessTimelineProvider: AppIntentTimelineProvider {

    func placeholder(in context: Context) -> ProcessWidgetEntry {
        ProcessWidgetEntry(
            date: .now,
            process: RemoteProcess(id: UUID(), name: "API Dev", command: "npm run dev", status: "running", pid: 4123),
            serverName: "Mac",
            updatedAt: .now
        )
    }

    func snapshot(for configuration: SelectProcessIntent, in context: Context) async -> ProcessWidgetEntry {
        makeEntry(for: configuration)
    }

    func timeline(for configuration: SelectProcessIntent, in context: Context) async -> Timeline<ProcessWidgetEntry> {
        let entry = makeEntry(for: configuration)
        // O app chama `reloadAllTimelines()` a cada novo snapshot;
        // este fallback cobre períodos longos sem abrir o app.
        let nextRefresh = Date().addingTimeInterval(30 * 60)
        return Timeline(entries: [entry], policy: .after(nextRefresh))
    }

    /// Resolve o processo configurado; se não houver seleção (ou ele foi
    /// removido no Mac), cai para o primeiro processo do snapshot.
    private func makeEntry(for configuration: SelectProcessIntent) -> ProcessWidgetEntry {
        guard let snapshot = ProcessSnapshotStore.load(), !snapshot.processes.isEmpty else {
            return ProcessWidgetEntry(date: .now, process: nil, serverName: nil, updatedAt: nil)
        }

        let selected = configuration.process.flatMap { entity in
            snapshot.processes.first { $0.id.uuidString == entity.id }
        }

        return ProcessWidgetEntry(
            date: .now,
            process: selected ?? snapshot.processes.first,
            serverName: snapshot.serverName,
            updatedAt: snapshot.updatedAt
        )
    }
}
