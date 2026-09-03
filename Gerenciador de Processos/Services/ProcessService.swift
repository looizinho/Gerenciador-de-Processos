@preconcurrency import Foundation

/// Buffer thread-safe que acumula a saída (stdout + stderr) de um processo,
/// mantendo apenas os últimos `maxBytes` para evitar consumo ilimitado de memória.
final class OutputBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var data = Data()
    private let maxBytes: Int

    init(maxBytes: Int = 32_768) {
        self.maxBytes = maxBytes
    }

    func append(_ chunk: Data) {
        guard !chunk.isEmpty else { return }
        lock.lock()
        defer { lock.unlock() }
        data.append(chunk)
        if data.count > maxBytes {
            data = data.suffix(maxBytes)
        }
    }

    /// Retorna o conteúdo acumulado como String UTF-8 (substituindo bytes inválidos).
    func string() -> String {
        lock.lock()
        defer { lock.unlock() }
        return String(data: data, encoding: .utf8)
            ?? String(decoding: data, as: UTF8.self)
    }
}

class ProcessService {
    private struct Running {
        let process: Foundation.Process
        let stdoutPipe: Pipe
        let stderrPipe: Pipe
        let buffer: OutputBuffer
    }

    private var runningProcesses: [UUID: Running] = [:]

    /// Inicia um processo e retorna o PID.
    /// `onTermination` é chamado na main queue com (id, terminationStatus, outputCapturado)
    /// quando o processo encerra — normalmente ou de forma inesperada.
    func start(
        _ managed: ManagedProcess,
        onTermination: @escaping (UUID, Int32, String) -> Void
    ) -> Int32? {
        let process = Foundation.Process()
        // Executa via shell para que variáveis (ex.: $PORT) nos argumentos sejam
        // expandidas — spawn direto via /usr/bin/env passaria "$PORT" literal.
        process.executableURL = URL(fileURLWithPath: "/bin/bash")

        // Define o diretório de trabalho se fornecido
        let pathTrimmed = managed.path.trimmingCharacters(in: .whitespaces)
        if !pathTrimmed.isEmpty {
            process.currentDirectoryPath = pathTrimmed
        }

        // Mescla as variáveis definidas pelo usuário sobre o ambiente herdado.
        // Elas são injetadas no ambiente do processo ANTES do run(), então o
        // shell já as enxerga ao expandir os argumentos (ex.: $PORT).
        // (Atribuir process.environment substitui tudo — sem o merge o PATH sumiria.)
        process.environment = mergedEnvironment(with: managed.environment)

        // Monta a linha de comando: comando + argumentos.
        // `exec` faz o shell se substituir pelo comando — o PID retornado já é
        // o do processo alvo e terminate() o mata diretamente (sem órfãos).
        var commandLine = managed.command
        let trimmed = managed.arguments.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            commandLine += " " + trimmed
        }
        process.arguments = ["-c", "exec \(commandLine)"]

        // Pipes + buffer para capturar stdout/stderr continuamente
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError  = stderrPipe

        let buffer = OutputBuffer()

        // readabilityHandler é invocado em uma background queue sempre que há dados
        // disponíveis. Quando availableData é vazio, o pipe chegou ao EOF.
        func attachReader(_ pipe: Pipe) {
            pipe.fileHandleForReading.readabilityHandler = { handle in
                let chunk = handle.availableData
                if chunk.isEmpty {
                    // EOF: interrompe o handler para parar os callbacks
                    handle.readabilityHandler = nil
                    return
                }
                buffer.append(chunk)
            }
        }
        attachReader(stdoutPipe)
        attachReader(stderrPipe)

        let id = managed.id

        // Drena qualquer dado restante e devolve o conteúdo acumulado.
        func drainAndRead() -> String {
            let restOut = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
            if !restOut.isEmpty { buffer.append(restOut) }
            let restErr = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            if !restErr.isEmpty { buffer.append(restErr) }
            return buffer.string()
        }

        process.terminationHandler = { proc in
            // Interrompe os handlers antes de drenar o resto
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil

            let status = proc.terminationStatus
            let output = drainAndRead()

            Task { @MainActor in
                onTermination(id, status, output)
            }
        }

        print("[ProcessService] Iniciando '\(managed.name)'")
        if !pathTrimmed.isEmpty {
            print("[ProcessService] Diretório: \(pathTrimmed)")
        }
        let envKeys = parseEnvironment(managed.environment).keys.sorted()
        if !envKeys.isEmpty {
            print("[ProcessService] Variáveis de ambiente: \(envKeys.joined(separator: ", "))")
        }
        print("[ProcessService] Comando: \(commandLine)")

        do {
            try process.run()
            print("[ProcessService] ✅ '\(managed.name)' iniciado com PID \(process.processIdentifier)")
            runningProcesses[managed.id] = Running(
                process: process,
                stdoutPipe: stdoutPipe,
                stderrPipe: stderrPipe,
                buffer: buffer
            )
            return process.processIdentifier
        } catch {
            print("[ProcessService] ❌ Falha ao iniciar '\(managed.name)': \(error)")
            stdoutPipe.fileHandleForReading.readabilityHandler = nil
            stderrPipe.fileHandleForReading.readabilityHandler = nil
            return nil
        }
    }

    func stop(_ managed: ManagedProcess) {
        guard let running = runningProcesses[managed.id] else { return }
        running.process.terminate()
        runningProcesses.removeValue(forKey: managed.id)
    }

    func stopAll(processes: [ManagedProcess]) {
        processes.forEach { stop($0) }
    }

    /// Retorna a saída capturada até o momento de um processo em execução, se existir.
    func currentOutput(for id: UUID) -> String? {
        runningProcesses[id]?.buffer.string()
    }

    /// Executa um comando action (ação) - não mantém referência do processo
    func executeAction(_ action: String, workingPath: String = "", environment: String = "") {
        let trimmedAction = action.trimmingCharacters(in: .whitespaces)
        guard !trimmedAction.isEmpty else { return }

        let process = Foundation.Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")

        // Mescla as variáveis definidas pelo usuário sobre o ambiente herdado
        process.environment = mergedEnvironment(with: environment)

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

    // MARK: - Ambiente

    /// Converte a string "CHAVE=valor CHAVE2=valor2" em dicionário.
    /// Tokens sem "=" são ignorados; o primeiro "=" separa chave de valor
    /// (o valor pode conter "=").
    private func parseEnvironment(_ raw: String) -> [String: String] {
        var env: [String: String] = [:]
        for token in raw.split(whereSeparator: { $0 == " " || $0 == "\t" || $0 == "\n" }) {
            guard let eq = token.firstIndex(of: "=") else { continue }
            let key   = String(token[token.startIndex..<eq])
            let value = String(token[token.index(after: eq)...])
            guard !key.isEmpty else { continue }
            env[key] = value
        }
        return env
    }

    /// Retorna o ambiente herdado do app mesclado com as variáveis do usuário
    /// (as do usuário prevalecem em caso de conflito).
    private func mergedEnvironment(with raw: String) -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env.merge(parseEnvironment(raw)) { _, new in new }
        return env
    }
}
