import SwiftUI
import Sparkle

struct ContentView: View {

    @State private var appVersion: String = ""
    @State private var buildNumber: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(.accentColor)

            Text("Sparkle Test")
                .font(.title)
                .fontWeight(.semibold)

            // Displays MARKETING_VERSION and CURRENT_PROJECT_VERSION,
            // populated from Info.plist when the view appears.
            Text("Version \(appVersion) (\(buildNumber))")
                .font(.title3)
                .foregroundColor(.secondary)
                .textSelection(.enabled)
            }
        .padding(32)
        .frame(
            minWidth: 300,
            idealWidth: 300,
            maxWidth: 300,
            minHeight: 300,
            idealHeight: 300,
            maxHeight: 300
        )
        .onAppear {
            let info = Bundle.main.infoDictionary
            appVersion = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
            buildNumber = info?["CFBundleVersion"] as? String ?? "Unknown"
        }
    }
}
