import AppIntents
import SwiftUI

/// Main application entry point for the RateBar menu bar utility.
@main
struct RateBarApp: App {
    var body: some Scene {
        MenuBarExtra("RateBar", systemImage: "dollarsign.circle") {
            Text("Hello")
        }
    }
}
