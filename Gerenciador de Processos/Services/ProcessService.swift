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

        // Define o diretório de trabalho se fornecido
        let pathTrimmed = managed.path.trimmingCharacters(in: .whitespaces)
        if !pathTrimmed.isEmpty {
            process.currentDirectoryPath = pathTrimmed
        }

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

        print("[ProcessService] Iniciando '\(managed.name)'")
        if !pathTrimmed.isEmpty {
            print("[ProcessService] Diretório: \(pathTrimmed)")
        }
        print("[ProcessService] Comando: /usr/bin/env \(args.joined(separator: " "))")

        do {
            try process.run()
            print("[ProcessService] ✅ '\(managed.name)' iniciado com PID \(process.processIdentifier)")
            runningProcesses[managed.id] = process
            return process.processIdentifier
        } catch {
            print("[ProcessService] ❌ Falha ao iniciar '\(managed.name)': \(error)")
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

    /// Executa um comando action (ação) - não mantém referência do processo
    func executeAction(_ action: String, workingPath: String = "") {
        let trimmedAction = action.trimmingCharacters(in: .whitespaces)
        guard !trimmedAction.isEmpty else { return }

        let process = Foundation.Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")

        // Define diretório de trabalho se fornecido
        let pathTrimmed = workingPath.trimmingCharacters(in: .whitespaces)
        if !pathTrimmed.isEmpty {
            process.currentDirectoryPath = pathTrimmed
        }

        process.arguments = ["-c", trimmedAction]
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        print("[ProcessService] Executando action: \(trimmedAction)")

        do {
            try process.run()
            print("[ProcessService] ✅ Action executada com sucesso")
        } catch {
            print("[ProcessService] ❌ Falha ao executar action: \(error)")
        }
    }
}
