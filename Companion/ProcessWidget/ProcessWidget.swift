import SwiftUI
import WidgetKit
import DeveloperToolsSupport

/// Widget que exibe o nome e o status (ativo/parado) do processo
/// escolhido pelo usuário na configuração.
struct ProcessWidget: Widget {
    let kind = "ProcessWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectProcessIntent.self, provider: ProcessTimelineProvider()) { entry in
            ProcessWidgetView(entry: entry)
        }
        .configurationDisplayName("Status de Processo")
        .description("Acompanhe se um processo do Mac está ativo.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
