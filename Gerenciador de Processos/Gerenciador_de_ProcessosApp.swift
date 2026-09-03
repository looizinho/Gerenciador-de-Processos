import SwiftUI
import AppKit

@main
struct Gerenciador_de_ProcessosApp: App {
    @State private var viewModel = ProcessManagerViewModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Ícone na barra de menus → abre a lista de processos como popover
        MenuBarExtra("Gerenciador de Processos", systemImage: "slider.horizontal.2.arrow.trianglehead.counterclockwise") {
            ProcessListView()
                .environment(viewModel)
        }
        .menuBarExtraStyle(.window)

        // Janela flutuante para adicionar novos processos
        Window("Adicionar Processo", id: "add-process") {
            AddProcessView()
                .environment(viewModel)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 420, height: 260)
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Oculta o ícone do Dock — o app vive apenas na barra de menus
        NSApp.setActivationPolicy(.accessory)
    }
}
