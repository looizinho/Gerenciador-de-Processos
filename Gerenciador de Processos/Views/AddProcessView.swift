import SwiftUI

struct AddProcessView: View {
    @Environment(ProcessManagerViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name      = ""
    @State private var command   = ""
    @State private var arguments = ""
    @State private var path      = ""
    @State private var environment = ""
    @State private var action    = ""
    @State private var autoStart = false
    @FocusState private var focusedField: Field?

    private enum Field { case name, command, arguments, path, environment, action }

    private var canAdd: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !command.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Adicionar Processo")
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
                field(
                    label: "Caminho",
                    placeholder: "Ex: /Users/nome/projeto  (opcional)",
                    text: $path,
                    focus: .path,
                    monospaced: true
                )
                field(
                    label: "Variáveis de Ambiente",
                    placeholder: "Ex: PORT=3000 NODE_ENV=dev  (opcional)",
                    text: $environment,
                    focus: .environment,
                    monospaced: true
                )
                field(
                    label: "Ação",
                    placeholder: "Ex: open http://localhost:5173  (opcional)",
                    text: $action,
                    focus: .action,
                    monospaced: true
                )

                Toggle("Iniciar automaticamente ao abrir o app", isOn: $autoStart)
                    .toggleStyle(.checkbox)
                    .help("O processo será iniciado sozinho sempre que o app for aberto")
            }

            HStack {
                Button("Cancelar") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Adicionar") {
                    viewModel.addProcess(
                        name:      name.trimmingCharacters(in: .whitespaces),
                        command:   command.trimmingCharacters(in: .whitespaces),
                        arguments: arguments.trimmingCharacters(in: .whitespaces),
                        path:      path.trimmingCharacters(in: .whitespaces),
                        environment: environment.trimmingCharacters(in: .whitespaces),
                        action:    action.trimmingCharacters(in: .whitespaces),
                        autoStart: autoStart
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canAdd)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 420)
        .onAppear { focusedField = .name }
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
                    case .arguments: focusedField = .path
                    case .path:      focusedField = .environment
                    case .environment: focusedField = .action
                    case .action:    break
                    }
                }
        }
    }
}

#Preview {
    AddProcessView()
        .environment(ProcessManagerViewModel())
}
