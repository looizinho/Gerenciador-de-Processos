import SwiftUI

struct AddProcessView: View {
    @Environment(ProcessManagerViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var name      = ""
    @State private var command   = ""
    @State private var arguments = ""
    @FocusState private var focusedField: Field?

    private enum Field { case name, command, arguments }

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
            }

            HStack {
                Button("Cancelar") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Adicionar") {
                    viewModel.addProcess(
                        name:      name.trimmingCharacters(in: .whitespaces),
                        command:   command.trimmingCharacters(in: .whitespaces),
                        arguments: arguments.trimmingCharacters(in: .whitespaces)
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
                    case .arguments: break
                    }
                }
        }
    }
}

#Preview {
    AddProcessView()
        .environment(ProcessManagerViewModel())
}
