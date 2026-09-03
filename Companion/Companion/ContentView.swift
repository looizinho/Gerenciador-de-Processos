//
//  ContentView.swift
//  Companion
//
//  Created by Luizinho on 03/09/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(CompanionConnection.self) private var connection

    var body: some View {
        NavigationStack {
            Group {
                switch connection.state {
                case .idle, .browsing:
                    StatusView(
                        systemImage: "magnifyingglass",
                        title: "Procurando o Mac…",
                        message: "Verifique se o Gerenciador de Processos está aberto no Mac, na mesma rede Wi-Fi."
                    )

                case .connecting(let server):
                    StatusView(
                        systemImage: "cable.connector.horizontal",
                        title: "Conectando…",
                        message: server
                    )

                case .connected(let server):
                    if connection.processes.isEmpty {
                        StatusView(
                            systemImage: "tray",
                            title: "Nenhum processo",
                            message: "Conectado a \(server). Adicione processos no Mac para vê-los aqui."
                        )
                    } else {
                        ProcessListView(processes: connection.processes)
                    }

                case .waiting(let message):
                    StatusView(
                        systemImage: "wifi.exclamationmark",
                        title: "Sem rede local",
                        message: message
                    )

                case .failed(let message):
                    StatusView(
                        systemImage: "exclamationmark.triangle",
                        title: "Conexão perdida",
                        message: "Tentando reconectar…\n(\(message))"
                    )
                }
            }
            .task { connection.start() }
            .navigationTitle("Processos")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    connectionBadge
                }
            }
        }
    }

    @ViewBuilder
    private var connectionBadge: some View {
        switch connection.state {
        case .connected(let server):
            Label(server, systemImage: "macbook")
                .font(.caption)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
        case .idle, .browsing, .connecting, .waiting:
            ProgressView().controlSize(.small)
        case .failed:
            Image(systemName: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                .foregroundStyle(.orange)
        }
    }
}

/// View de estado vazio/erro usada nas telas sem lista.
private struct StatusView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
    }
}

#Preview {
    let connection = CompanionConnection()
    return ContentView()
        .environment(connection)
}
