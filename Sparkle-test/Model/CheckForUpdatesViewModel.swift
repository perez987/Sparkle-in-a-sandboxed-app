import SwiftUI
import Sparkle

// Observes `canCheckForUpdates` on the Sparkle updater and publishes it
// so views can enable/disable the update-check button reactively.
final class CheckForUpdatesViewModel: ObservableObject {
    @Published var canCheckForUpdates = false

    init(updater: SPUUpdater) {
        updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
    }
}

// A view used in both the main window and the application menu
// to trigger a manual update check.
struct CheckForUpdatesView: View {
    @ObservedObject var checkForUpdatesViewModel: CheckForUpdatesViewModel
    let updater: SPUUpdater

    var body: some View {
        Button("Check for Updates…", action: updater.checkForUpdates)
            .disabled(!checkForUpdatesViewModel.canCheckForUpdates)
    }
}
