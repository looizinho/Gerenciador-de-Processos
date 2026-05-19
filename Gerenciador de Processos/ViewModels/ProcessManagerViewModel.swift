import SwiftUI
import AppKit
import Observation

@Observable
class ProcessManagerViewModel {
    var processes: [ManagedProcess] = []

    private let processService     = ProcessService()
    private let persistenceService = PersistenceService()

    init() {
        processes = persistenceService.load()

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.terminateAllProcesses()
        }
    }

    // MARK: - CRUD

    func addProcess(name: String, command: String, arguments: String) {
        let process = ManagedProcess(name: name, command: command, arguments: arguments)
        processes.append(process)
        persistenceService.save(processes)
    }

    func removeProcess(_ process: ManagedProcess) {
        if process.status == .running { processService.stop(process) }
        processes.removeAll { $0.id == process.id }
        persistenceService.save(processes)
    }

    func removeProcesses(at offsets: IndexSet) {
        for index in offsets where processes[index].status == .running {
            processService.stop(processes[index])
        }
        processes.remove(atOffsets: offsets)
        persistenceService.save(processes)
    }

    // MARK: - Lifecycle

    func startProcess(_ process: ManagedProcess) {
        guard let index = processes.firstIndex(where: { $0.id == process.id }) else { return }

        let pid = processService.start(process) { [weak self] id in
            guard let self,
                  let idx = self.processes.firstIndex(where: { $0.id == id }) else { return }
            self.processes[idx].status = .stopped
            self.processes[idx].pid    = nil
        }

        if let pid {
            processes[index].status = .running
            processes[index].pid    = pid
        }
    }

    func stopProcess(_ process: ManagedProcess) {
        guard let index = processes.firstIndex(where: { $0.id == process.id }) else { return }
        processService.stop(process)
        processes[index].status = .stopped
        processes[index].pid    = nil
    }

    func terminateAllProcesses() {
        processService.stopAll(processes: processes.filter { $0.status == .running })
    }
}
