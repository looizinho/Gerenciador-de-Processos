//
//  CompanionApp.swift
//  Companion
//
//  Created by Luizinho on 03/09/26.
//

import SwiftUI

@main
struct CompanionApp: App {
    @State private var connection = CompanionConnection()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(connection)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                // Inicia a descoberta/conexão ao abrir ou voltar ao app
                connection.start()
            case .background:
                // TCP não sobrevive em background no iOS — reconecta ao voltar
                connection.stop()
            default:
                break
            }
        }
    }
}
