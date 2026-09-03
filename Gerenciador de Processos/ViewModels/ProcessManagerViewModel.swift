import SwiftUI
import AppKit
import Observation

@Observable
class ProcessManagerViewModel {
    var processes: [ManagedProcess] = []

    private let processService     = ProcessService()
    private let persistenceService = PersistenceService()
    private let remoteServer       = RemoteServer()

    init() {
        processes = persistenceService.load()
        remoteServer.start()
        publishRemote()

        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.terminateAllProcesses()
        }

        // Inicia automaticamente os processos marcados com `autoStart` ao abrir o app
        NotificationCenter.default.addObserver(
            forName: NSApplication.didFinishLaunchingNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.startAutoStartProcesses()
        }
    }

    /// Envia a lista atual de processos ao Companion (rede local).
    private func publishRemote() {
        remoteServer.publish(processes: processes)
    }

    // MARK: - CRUD

    func addProcess(name: String, command: String, arguments: String, path: String = "", environment: String = "", action: String = "", autoStart: Bool = false) {
        let process = ManagedProcess(name: name, command: command, arguments: arguments, path: path, environment: environment, action: action, autoStart: autoStart)
        processes.append(process)
        persistenceService.save(processes)
        publishRemote()
    }

    func removeProcess(_ process: ManagedProcess) {
        if process.status == .running { processService.stop(process) }
        processes.removeAll { $0.id == process.id }
        persistenceService.save(processes)
        publishRemote()
    }

    func updateProcess(id: UUID, name: String, command: String, arguments: String, path: String = "", environment: String = "", action: String = "", autoStart: Bool = false) {
        guard let index = processes.firstIndex(where: { $0.id == id }) else { return }
        processes[index].name = name
        processes[index].command = command
        processes[index].arguments = arguments
        processes[index].path = path
        processes[index].environment = environment
        processes[index].action = action
        processes[index].autoStart = autoStart
        persistenceService.save(processes)
        publishRemote()
    }

    func removeProcesses(at offsets: IndexSet) {
        for index in offsets where processes[index].status == .running {
            processService.stop(processes[index])
        }
        processes.remove(atOffsets: offsets)
        persistenceService.save(processes)
        publishRemote()
    }

    // MARK: - Lifecycle

    func startProcess(_ process: ManagedProcess) {
        print("[ViewModel] startProcess chamado para '\(process.name)'")
        guard let index = processes.firstIndex(where: { $0.id == process.id }) else {
            print("[ViewModel] ❌ Processo não encontrado no array")
            return
        }

        // Limpa estado de término anterior ao (re)iniciar
        processes[index].output = ""
        processes[index].exitReason = ""

        print("[ViewModel] Encontrado em índice \(index), chamando processService.start()")
        let pid = processService.start(process) { [weak self] id, status, output in
            print("[ViewModel] terminationHandler chamado para \(id) — status \(status)")
            guard let self,
                  let idx = self.processes.firstIndex(where: { $0.id == id }) else {
                print("[ViewModel] ❌ Self ou índice não encontrado no callback")
                return
            }
            self.processes[idx].status = .stopped
            self.processes[idx].pid    = nil
            self.processes[idx].output = output
            self.processes[idx].exitReason = Self.reason(for: status, output: output)
            print("[ViewModel] Processo marcado como stopped — \(self.processes[idx].exitReason)")
            self.publishRemote()
        }

        if let pid {
            print("[ViewModel] ✅ PID \(pid) retornado, atualizando status para running")
            processes[index].status = .running
            processes[index].pid    = pid
            publishRemote()
        } else {
            print("[ViewModel] ❌ processService.start() retornou nil")
        }
    }

    func stopProcess(_ process: ManagedProcess) {
        guard let index = processes.firstIndex(where: { $0.id == process.id }) else { return }
        processService.stop(process)
        processes[index].status = .stopped
        processes[index].pid    = nil
        publishRemote()
    }

    /// Inicia os processos marcados com `autoStart` que estiverem parados.
    func startAutoStartProcesses() {
        for process in processes where process.autoStart && process.status == .stopped {
            startProcess(process)
        }
    }

    func executeAction(_ process: ManagedProcess) {
        guard process.status == .running else { return }
        processService.executeAction(process.action, workingPath: process.path, environment: process.environment)
    }

    func terminateAllProcesses() {
        processService.stopAll(processes: processes.filter { $0.status == .running })
    }

    // MARK: - Helpers

    /// Constrói uma descrição legível do motivo do término a partir do status e da saída.
    private static func reason(for status: Int32, output: String) -> String {
        if status == 0 {
            return "Encerrou normalmente (código 0)"
        }
        // Tenta extrair a última linha não vazia da saída, que costuma trazer o erro.
        let lastLine = output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .last?
            .trimmingCharacters(in: .whitespaces)
            ?? ""
        if lastLine.isEmpty {
            return "Encerrou com código \(status)"
        }
        return "Encerrou com código \(status): \(lastLine)"
    }
}
