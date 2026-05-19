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

    func addProcess(name: String, command: String, arguments: String, path: String = "", action: String = "") {
        let process = ManagedProcess(name: name, command: command, arguments: arguments, path: path, action: action)
        processes.append(process)
        persistenceService.save(processes)
    }

    func removeProcess(_ process: ManagedProcess) {
        if process.status == .running { processService.stop(process) }
        processes.removeAll { $0.id == process.id }
        persistenceService.save(processes)
    }

    func updateProcess(id: UUID, name: String, command: String, arguments: String, path: String = "", action: String = "") {
        guard let index = processes.firstIndex(where: { $0.id == id }) else { return }
        processes[index].name = name
        processes[index].command = command
        processes[index].arguments = arguments
        processes[index].path = path
        processes[index].action = action
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
        print("[ViewModel] startProcess chamado para '\(process.name)'")
        guard let index = processes.firstIndex(where: { $0.id == process.id }) else {
            print("[ViewModel] ❌ Processo não encontrado no array")
            return
        }

        print("[ViewModel] Encontrado em índice \(index), chamando processService.start()")
        let pid = processService.start(process) { [weak self] id in
            print("[ViewModel] terminationHandler chamado para \(id)")
            guard let self,
                  let idx = self.processes.firstIndex(where: { $0.id == id }) else {
                print("[ViewModel] ❌ Self ou índice não encontrado no callback")
                return
            }
            self.processes[idx].status = .stopped
            self.processes[idx].pid    = nil
            print("[ViewModel] Processo marcado como stopped")
        }

        if let pid {
            print("[ViewModel] ✅ PID \(pid) retornado, atualizando status para running")
            processes[index].status = .running
            processes[index].pid    = pid
        } else {
            print("[ViewModel] ❌ processService.start() retornou nil")
        }
    }

    func stopProcess(_ process: ManagedProcess) {
        guard let index = processes.firstIndex(where: { $0.id == process.id }) else { return }
        processService.stop(process)
        processes[index].status = .stopped
        processes[index].pid    = nil
    }

    func executeAction(_ process: ManagedProcess) {
        guard process.status == .running else { return }
        processService.executeAction(process.action, workingPath: process.path)
    }

    func terminateAllProcesses() {
        processService.stopAll(processes: processes.filter { $0.status == .running })
    }
}
