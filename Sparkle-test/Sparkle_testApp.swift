import SwiftUI
import Sparkle

@main
struct Sparkle_testApp: App {
    @StateObject private var updaterController = UpdaterController()
    @State private var isLanguageSelectorPresented = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $isLanguageSelectorPresented) {
                    LanguageSelectorView()
                }
        }
                .windowResizability(.contentSize)
                .commands {
                    // Add "Check for Updates…" to the application menu
                    CommandGroup(after: .appInfo) {
                        Button(
                            NSLocalizedString(
                                "Check for Updates...",
                                comment: "Menu item to check for app updates"
                            ),
                            systemImage: "arrow.triangle.2.circlepath"
                        ) {
                            updaterController.checkForUpdates()
                        }
                        .keyboardShortcut("u", modifiers: [.command])
                        .disabled(!updaterController.canCheckForUpdates)
                    }
                    // Add Language menu before Window menu
                    CommandGroup(replacing: .newItem) { }
                    CommandMenu(NSLocalizedString("Language menu", comment: "Language menu")) {
                        Button(NSLocalizedString("Select Language menu item", comment: "Select Language menu item")) {
                            isLanguageSelectorPresented = true
                        }
                        .keyboardShortcut("l", modifiers: .command)
                    }
        }
    }
}
