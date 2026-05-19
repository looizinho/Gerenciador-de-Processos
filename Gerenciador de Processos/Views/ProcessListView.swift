import SwiftUI
import AppKit

struct ProcessListView: View {
    @Environment(ProcessManagerViewModel.self) private var viewModel
    @Environment(\.openWindow) private var openWindow

    private var runningCount: Int {
        viewModel.processes.filter { $0.status == .running }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 420, height: 380)
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "server.rack")
                .foregroundStyle(.secondary)
            Text("Gerenciador de Processos")
                .font(.headline)
            Spacer()
            Button {
                openWindow(id: "add-process")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
            .help("Adicionar processo")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if viewModel.processes.isEmpty {
            emptyState
        } else {
            processList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "server.rack")
                .font(.system(size: 36))
                .foregroundStyle(.quaternary)
            Text("Nenhum processo configurado")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Clique em + para adicionar um servidor ou serviço")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var processList: some View {
        List {
            ForEach(viewModel.processes) { process in
                ProcessRowView(process: process)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            }
            .onDelete { viewModel.removeProcesses(at: $0) }
        }
        .listStyle(.plain)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if !viewModel.processes.isEmpty {
                Text(runningCount == 0
                     ? "Nenhum processo em execução"
                     : "\(runningCount) processo\(runningCount > 1 ? "s" : "") em execução")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Encerrar App") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

// MARK: - ProcessRowView

struct ProcessRowView: View {
    @Environment(ProcessManagerViewModel.self) private var viewModel
    let process: ManagedProcess

    private var isRunning: Bool { process.status == .running }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(isRunning ? Color.green : Color.gray.opacity(0.35))
                .frame(width: 8, height: 8)
                .animation(.easeInOut(duration: 0.2), value: isRunning)

            VStack(alignment: .leading, spacing: 2) {
                Text(process.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(commandPreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            if isRunning, let pid = process.pid {
                Text("PID \(pid)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }

            Button(isRunning ? "Stop" : "Start") {
                if isRunning {
                    viewModel.stopProcess(process)
                } else {
                    viewModel.startProcess(process)
                }
            }
            .buttonStyle(.bordered)
            .tint(isRunning ? .red : .green)
            .controlSize(.small)
        }
    }

    private var commandPreview: String {
        process.arguments.isEmpty
            ? process.command
            : "\(process.command) \(process.arguments)"
    }
}

#Preview {
    ProcessListView()
        .environment(ProcessManagerViewModel())
}
