import SwiftUI
import Sparkle

@main
struct Sparkle_testApp: App {
    @StateObject private var updaterController = UpdaterController()

    var body: some Scene {
        WindowGroup {
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
            }
        }
    }
