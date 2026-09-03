import SwiftUI

/// Lista os processos gerenciados recebidos do Mac.
struct ProcessListView: View {
    let processes: [RemoteProcess]

    var body: some View {
        List(processes) { process in
            ProcessRow(process: process)
        }
        .listStyle(.plain)
    }
}

struct ProcessRow: View {
    let process: RemoteProcess

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(process.isRunning ? .green : .gray.opacity(0.5))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(process.name)
                    .font(.headline)

                Text(process.command)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(process.isRunning ? "Ativo" : "Parado")
                    .font(.caption)
                    .foregroundStyle(process.isRunning ? .green : .secondary)

                if let pid = process.pid, process.isRunning {
                    Text("PID \(pid)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .monospacedDigit()
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(process.name), \(process.isRunning ? "ativo" : "parado")")
    }
}

#Preview {
    ProcessListView(processes: [
        RemoteProcess(id: UUID(), name: "API Dev", command: "npm run dev", status: "running", pid: 4123),
        RemoteProcess(id: UUID(), name: "Postgres", command: "postgres -D /data", status: "stopped", pid: nil),
    ])
}
