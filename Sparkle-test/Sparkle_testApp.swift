import SwiftUI
import Sparkle

@main
struct Sparkle_testApp: App {
    private let updaterController: SPUStandardUpdaterController
    @StateObject private var checkForUpdatesViewModel: CheckForUpdatesViewModel

    init() {
        // Start the updater as early as possible at app launch.
        // Sparkle requires the controller to be initialized before any UI is shown.
        let controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        updaterController = controller
        _checkForUpdatesViewModel = StateObject(
            wrappedValue: CheckForUpdatesViewModel(updater: controller.updater)
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                updater: updaterController.updater,
                checkForUpdatesViewModel: checkForUpdatesViewModel
            )
        }
        .commands {
            // Add "Check for Updates…" to the application menu
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(
                    checkForUpdatesViewModel: checkForUpdatesViewModel,
                    updater: updaterController.updater
                )
            }
        }
    }
}
