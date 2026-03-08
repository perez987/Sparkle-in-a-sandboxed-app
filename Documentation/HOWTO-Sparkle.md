# Sparkle-test: Setup Instructions

This file describes everything you need to do after cloning this repository to build and run **Sparkle-test**, a sandboxed SwiftUI macOS app that uses the Sparkle update framework (v2.x).

## 1. Prerequisites

| Requirement | Version |
|---|---|
| Xcode | 15+ |
| macOS | 13 Sonoma or later |
| Apple ID or Developer Account | Required for code signing |
| Sparkle | 2.x — added via Swift Package Manager |

## 2. Open the Project in Xcode

1. Open `Sparkle-test.xcodeproj` in Xcode.
2. Xcode will automatically resolve the **Sparkle** Swift Package dependency from  
   `https://github.com/sparkle-project/Sparkle` (version ≥ 2.0.0).  
   Wait for the "Resolving Package Graph" spinner to finish.

## 3. Configure Code Signing

1. In Xcode, select the **Sparkle-test** project in the Project Navigator.
2. Select the **Sparkle-test** target → **Signing & Capabilities**.
3. Under **Signing**:
   - Set **Team** to your Apple ID.
   - Keep **Automatically manage signing** enabled.
   - Set **Sign to Run Locally**
   - The **Bundle Identifier** is pre-set to `com.perez987.Sparkle-test`.

### About "ad-hoc" signing with your Apple ID  

For other users running this app (outside App Store), they do **not** need a Developer ID certificate but get a Gatekeeper warning the first time they run the app.

In pre-Sequoia versions, the Gatekeeper warning for files downloaded from the Internet had a simple solution: accepting the warning when opening the file or right-clicking on the file >> Open.

But in Sequoia and Tahoe, the warning is more shocking and might upset the user. The fix is to remove the `com.apple.quarantine` attribute so that, from this point on, you can run the app without issues.

You can read about this in [APP is damaged and can't be opened](APP-damaged.md).

## 4. Generate Sparkle EdDSA Keys

Sparkle 2 uses EdDSA (`Ed25519`) signatures to verify update packages.  
You must generate a key pair and add the **public key** to `Info.plist`.

### Steps

1. Locate `generate_keys` inside the Sparkle package (Xcode downloads packages to `~/Library/Developer/Xcode/DerivedData/<project>/SourcePackages/`) or download Sparkle-2.x.x.tar.xz from GitHub [releases](https://github.com/sparkle-project/Sparkle/releases)
2. Extract the binary distribution and run generate_keys

```bash
./bin/generate_keys
```

The tool will:

- Print a **private key** — by default, Sparkle saves it in the macOS Keychain. **Never commit it.**
- Print a **public key** (Base64 string).

### Add the Public Key to Info.plist

Add this to the `Info.plist` file:

```xml
<key>SUPublicEDKey</key>
<string>BASE64_PUBLIC_KEY</string>
```

**Important:** Without the correct `SUPublicEDKey`, Sparkle will refuse to install updates.

## 5. Set Up an Appcast Feed

Sparkle checks a remote XML feed ("appcast") to discover new versions.

### 5a. Create the Appcast XML

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>Sparkle-test</title>
    <item>
      <title>Version 1.0.1</title>
      <sparkle:version>4</sparkle:version>
      <sparkle:shortVersionString>1.0.1</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>13.0</sparkle:minimumSystemVersion>
      <pubDate>Fri, 01 Jan 2025 12:00:00 +0000</pubDate>
      <enclosure
        url="https://github.com/perez987/Sparkle-test/releases/download/1.0.1/Sparkle-test-1.0.1.zip"
        sparkle:edSignature="ED_SIGNATURE"
        length="1234567"
        type="application/octet-stream"
      />
    </item>
  </channel>
</rss>
```

#### appcast.xml components:

- link: repository web address
- language: predefined language
- item: to set more than one release
- title: you can set the version number
- description empty: Sparkle displays a smaller update dialog, without version notes
- description with HTML text between CDATA tags: Sparkle displays a larger update dialog where we can see the release notes
- enclosure: version-specific data
	- url -> link to the app ZIP file
	- sparkle:version -> project build number (`CURRENT_PROJECT_VERSION`)
	- sparkle:shortVersionString-> app version (`MARKETING_VERSION`)
	- length -> app ZIP file in bytes
	- sparkle:edSignature -> public EdDSA key for verifying update signatures
	- type -> "application/octet-stream"
	- minimumSystemVersion -> min. version of Xcode target

### 5b. Sign the Update Package

```bash
# Generate the .zip of the new version's .app bundle
zip -r Sparkle-test-1.1.zip Sparkle-test.app

# Sign it with your private key using Sparkle's sign_update tool
./bin/sign_update Sparkle-test-1.1.zip
```

Prints the ZIP size in bytes (`length`) and the EdDSA signature (`sparkle:edSignature`) to paste into the appcast.

### 5c. Host the Appcast

Upload `appcast.xml` to the root of the repository and the `.zip` file to the releases page.

### 5d. Update Info.plist

Replace the placeholder `SUFeedURL` in `Sparkle-test/Info.plist`:

```xml
<key>SUFeedURL</key>
<string>https://raw.githubusercontent.com/perez987/Sparkle-test/main/appcast.xml</string>
```

## 6. Sandbox Entitlements Explained

The file `Sparkle-test.entitlements` contains:

- com.apple.security.app-sandbox: true
   - Enables the macOS App Sandbox
- com.apple.security.network.client: true
   - Allows outgoing connections (appcast + update download)
- com.apple.security.files.user-selected.read-only: true
   - User-selected files: read-only access
- com.apple.security.temporary-exception.mach-lookup.global-name: […-spks, …-spki]
   - Allows communication with Sparkle's XPC helper services
- com.apple.security.temporary-exception.shared-preference.read-write: [bundle-id]
   - Allows Sparkle to store update state in shared defaults

**Why temporary exceptions?**

Sparkle 2 uses two private XPC services bundled inside `Sparkle.framework`:

- `Sparkle Downloader.xpc` — downloads updates from the network
- `Sparkle Installer.xpc` — applies updates to the app bundle. 

The `mach-lookup` exceptions allow the sandboxed app to find and communicate with these services.

## 7. Build & Run

1. Select the **Sparkle-test** scheme and your Mac as the destination.
2. Press **⌘R** to build and run.
3. The app window shows the current version (marketing version and build number).
4. A **Check for Updates…** menu item is available in the application menu (also reachable via **⌘U**). It is disabled until Sparkle finishes its startup check; it becomes enabled after a few seconds.

## 8. Testing the Update Flow (End-to-End)

To test a full update cycle without a public server, you can use a local HTTP server:

```bash
# Serve files on localhost:8080
python3 -m http.server 8080 --directory /path/to/your/update/files
```

Point `SUFeedURL` in `Info.plist` to `http://localhost:8080/appcast.xml` temporarily.

> **Note:** For local testing you can omit `SUPublicEDKey` and remove the `SURequireSignedFeed` key, but **always re-enable them** for production.

## 9. Creating a Distributable Build

Since this app will **not be notarized** (signed ad-hoc with your Apple ID):

1. Archive the app: **Product → Archive** in Xcode.
2. In the Organizer, click **Distribute App** → **Direct Distribution** (or **Copy App**).
3. The resulting `.app` bundle can be run on **your own Mac** without Gatekeeper issues  
   (Gatekeeper will block it on other Macs unless notarized or the user removes the quarantine attribute).

## 10. Project File Structure

```
Sparkle-test/
├── Sparkle-test.xcodeproj/             Xcode project file
│   └── project.pbxproj
├── Sparkle-test/                       Swift source & resources
│   ├── Sparkle_testApp.swift           App entry point; creates UpdaterController and adds "Check for Updates…" to the app menu
│   ├── Views/
│   │   └── ContentView.swift           Main window: app icon, title, and version/build number text
│   ├── Model/
│   │   └── UpdateController.swift      ObservableObject (UpdaterController) that wraps SPUStandardUpdaterController and publishes canCheckForUpdates
│   ├── Info.plist                      App metadata + Sparkle keys (SUFeedURL, SUPublicEDKey…)
│   ├── Sparkle-test.entitlements       Sandbox + network + Sparkle mach exceptions
│   └── Assets.xcassets/                App icon + accent colour
└── LICENSE
```

## 11. Key Sparkle 2 Info.plist Settings

| Key | Description |
|---|---|
| `SUFeedURL` | **Required**: HTTPS URL to your `appcast.xml` |
| `SUPublicEDKey` | **Required for production**: Base64 EdDSA public key for update verification |
| `SUEnableInstallerLauncherService` | **Required for sandbox**: Allows Sparkle to launch its installer XPC service |
| `SUEnableSystemProfiling` | Set `false` to disable anonymous analytics |
| `SUScheduledCheckInterval` | Seconds between automatic update checks (set to 604800 = 1 week in this project) |

## 12. Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| "Check for Updates" always disabled | Updater failed to start | Check Console for Sparkle errors; ensure `SUFeedURL` is reachable |
| Sandbox violation in Console | Missing entitlement | Verify `mach-lookup` exceptions in entitlements file match bundle ID |
| Update download fails silently | Missing `network.client` entitlement or wrong URL | Check entitlements; verify appcast URL is HTTPS |
| "Update can't be installed" | Missing `SUEnableInstallerLauncherService` | Add/verify that key is `true` in `Info.plist` |
| Signature verification fails | Wrong or missing `SUPublicEDKey` | Re-generate keys and update `Info.plist` |
| App not opening on another Mac | Not notarized | - Right-click the app → Open<br>- Remove quarantine atribute<br>- If Apple Developer account, notarize for distribution |

## References

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Sparkle Sandboxing Guide](https://sparkle-project.org/documentation/sandboxing/)
- [Sparkle Publishing Updates](https://sparkle-project.org/documentation/publishing/)
- [Sparkle GitHub Releases](https://github.com/sparkle-project/Sparkle/releases)

---
🌐 [Versión en español](HOWTO-Sparkle-es.md)
