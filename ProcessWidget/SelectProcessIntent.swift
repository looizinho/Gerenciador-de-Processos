import AppIntents

/// Configuração do widget: permite ao usuário escolher qual processo
/// do Mac será exibido.
struct SelectProcessIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Selecionar Processo"
    static var description = IntentDescription("Escolhe o processo que o widget vai acompanhar.")

    @Parameter(title: "Processo")
    var process: ProcessEntity?

    init() { }

    init(process: ProcessEntity?) {
        self.process = process
    }

    func perform() async throws -> some IntentResult {
        .result()
    }
}

/// Processo do Mac exposto ao seletor de configuração do widget.
struct ProcessEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Processo"
    static var defaultQuery: ProcessQuery = ProcessQuery()

    let id: String   // UUID do processo no Gerenciador
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

/// Lista os processos do último snapshot recebido do Mac
/// (persistido no App Group pelo app Companion).
struct ProcessQuery: EntityQuery {

    init() { }

    func entities(for identifiers: [String]) async throws -> [ProcessEntity] {
        availableProcesses().filter { identifiers.contains($0.id) }
    }

    /// Processos oferecidos na tela de configuração do widget.
    func suggestedEntities() async throws -> [ProcessEntity] {
        availableProcesses()
    }

    /// Sugestão inicial quando o usuário ainda não escolheu nada.
    func defaultResult() async -> ProcessEntity? {
        availableProcesses().first
    }

    private func availableProcesses() -> [ProcessEntity] {
        (ProcessSnapshotStore.load()?.processes ?? []).map {
            ProcessEntity(id: $0.id.uuidString, name: $0.name)
        }
    }
}
