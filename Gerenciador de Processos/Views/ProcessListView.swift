import SwiftUI
import AppKit

struct ProcessListView: View {
    @Environment(ProcessManagerViewModel.self) private var viewModel
    @Environment(\.openWindow) private var openWindow

    @State private var editingProcess: ManagedProcess?

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
        .sheet(item: $editingProcess) { process in
            EditProcessView(
                process: process,
                onSave: { name, command, arguments in
                    viewModel.updateProcess(
                        id: process.id,
                        name: name,
                        command: command,
                        arguments: arguments
                    )
                    editingProcess = nil
                },
                onCancel: {
                    editingProcess = nil
                }
            )
            .environment(viewModel)
        }
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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            editingProcess = process
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.removeProcess(process)
                        } label: {
                            Image(systemName: "trash.circle.fill")
                        }
                    }
            }
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
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power.circle.fill")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Encerrar aplicativo")
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

// MARK: - EditProcessView

struct EditProcessView: View {
    let process: ManagedProcess
    let onSave: (String, String, String) -> Void
    let onCancel: () -> Void

    @State private var name      = ""
    @State private var command   = ""
    @State private var arguments = ""
    @FocusState private var focusedField: Field?

    private enum Field { case name, command, arguments }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !command.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Editar Processo")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                field(
                    label: "Nome",
                    placeholder: "Ex: Servidor Vite",
                    text: $name,
                    focus: .name
                )
                field(
                    label: "Comando",
                    placeholder: "Ex: npm",
                    text: $command,
                    focus: .command,
                    monospaced: true
                )
                field(
                    label: "Argumentos",
                    placeholder: "Ex: run dev  (opcional)",
                    text: $arguments,
                    focus: .arguments,
                    monospaced: true
                )
            }

            HStack {
                Button("Cancelar") {
                    onCancel()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Salvar") {
                    onSave(
                        name.trimmingCharacters(in: .whitespaces),
                        command.trimmingCharacters(in: .whitespaces),
                        arguments.trimmingCharacters(in: .whitespaces)
                    )
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear {
            name = process.name
            command = process.command
            arguments = process.arguments
            focusedField = .name
        }
    }

    @ViewBuilder
    private func field(
        label: String,
        placeholder: String,
        text: Binding<String>,
        focus: Field,
        monospaced: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .font(monospaced ? .system(.body, design: .monospaced) : .body)
                .focused($focusedField, equals: focus)
                .onSubmit {
                    switch focus {
                    case .name:      focusedField = .command
                    case .command:   focusedField = .arguments
                    case .arguments: break
                    }
                }
        }
    }
}

#Preview {
    ProcessListView()
        .environment(ProcessManagerViewModel())
}
