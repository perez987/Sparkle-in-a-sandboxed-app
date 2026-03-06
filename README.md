# Sparkle updater system in a SwiftUI sandboxed app

Testing site to learn how to implement Sparkle updater system in **Sparkle-test**, a sandboxed SwiftUI macOS app that uses the Sparkle update framework (v2.x).

Deploying Sparkle in an Xcode SwiftUI project without sandboxing is usually quite straightforward and generates few issues.

However, many users (myself included) find that deploying Sparkle in a sandboxed app is considerably more difficult. Security and permission issues frequently lead to failure. This repository was created to test a working configuration.

## Project and app requirements

Project and app requirements were:

- The app must be sandboxed, as my challenge is implementing Sparkle in sandboxed apps. Non-sandboxed apps are easy to populate with Sparkle
- The app is not notarized by Apple, only signed ad hoc with my Apple ID
- Xcode project must have an `.entitlements` file.
- Basic sandbox conditions are:
   - user files read-only
   - outgoing connections allowed

Detailed instructions are available in the [HOWTO-Sparkle](HOWTO-Sparkle.md) file
