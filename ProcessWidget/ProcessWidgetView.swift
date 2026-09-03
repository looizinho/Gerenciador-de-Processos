import SwiftUI
import WidgetKit
import DeveloperToolsSupport

/// Conteúdo do widget: nome e status do processo escolhido.
struct ProcessWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: ProcessWidgetEntry

    var body: some View {
        Group {
            if let process = entry.process {
                switch family {
                case .systemMedium:
                    mediumContent(process: process)
                default:
                    smallContent(process: process)
                }
            } else {
                emptyContent
            }
        }
        .containerBackground(.regularMaterial, for: .widget)
    }

    // MARK: - Famílias

    private func smallContent(process: RemoteProcess) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            StatusBadge(isRunning: process.isRunning)

            Spacer(minLength: 0)

            Text(process.name)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            footer
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func mediumContent(process: RemoteProcess) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(process.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(process.command)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer(minLength: 0)

                footer
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 6) {
                StatusBadge(isRunning: process.isRunning)

                if let pid = process.pid, process.isRunning {
                    Text("PID \(pid)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
        }
    }

    /// Mostrado quando ainda não há snapshot (app nunca conectou).
    private var emptyContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "macbook.and.iphone")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Abra o Companion para sincronizar os processos do Mac.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Componentes

    private var footer: some View {
        HStack(spacing: 4) {
            if let server = entry.serverName {
                Text(server)
            }
            if entry.serverName != nil && entry.updatedAt != nil {
                Text("·")
            }
            if let updatedAt = entry.updatedAt {
                Text(updatedAt, style: .time)
            }
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .lineLimit(1)
    }
}

/// Selo de status: verde quando ativo, cinza quando parado.
private struct StatusBadge: View {
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isRunning ? .green : .gray)
                .frame(width: 7, height: 7)
            Text(isRunning ? "Ativo" : "Parado")
                .font(.caption2.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(isRunning ? Color.green.opacity(0.18) : Color.gray.opacity(0.18))
        )
        .foregroundStyle(isRunning ? .green : .secondary)
        .accessibilityLabel(isRunning ? "Ativo" : "Parado")
    }
}
