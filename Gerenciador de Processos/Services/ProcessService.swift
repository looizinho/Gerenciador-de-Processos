@preconcurrency import Foundation

class ProcessService {
    private var runningProcesses: [UUID: Foundation.Process] = [:]

    /// Inicia um processo e retorna o PID. O callback `onTermination` é chamado
    /// na main queue quando o processo encerra (normalmente ou de forma inesperada).
    func start(
        _ managed: ManagedProcess,
        onTermination: @escaping (UUID) -> Void
    ) -> Int32? {
        let process = Foundation.Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")

        // Monta os argumentos: comando + argumentos separados por espaço
        var args = [managed.command]
        let trimmed = managed.arguments.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            args += trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        }
        process.arguments = args

        // Captura stdout/stderr para evitar erros de pipe quebrado
        process.standardOutput = Pipe()
        process.standardError  = Pipe()

        let id = managed.id
        process.terminationHandler = { _ in
            Task { @MainActor in
                onTermination(id)
            }
        }

        do {
            try process.run()
            runningProcesses[managed.id] = process
            return process.processIdentifier
        } catch {
            print("[ProcessService] Falha ao iniciar '\(managed.name)': \(error.localizedDescription)")
            return nil
        }
    }

    func stop(_ managed: ManagedProcess) {
        guard let process = runningProcesses[managed.id] else { return }
        process.terminate()
        runningProcesses.removeValue(forKey: managed.id)
    }

    func stopAll(processes: [ManagedProcess]) {
        processes.forEach { stop($0) }
    }
}
