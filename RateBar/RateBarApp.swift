import AppIntents
import AppKit
import SwiftUI

/// Main application entry point for the RateBar menu bar utility.
@main
@MainActor
struct RateBarApp: App {
    @State private var rateService = RateService(client: ExchangeRateHostClient())

    var body: some Scene {
        MenuBarExtra {
            MenuContent(
                snapshot: rateService.snapshot,
                lastError: rateService.lastError,
                isStale: rateService.isStale,
                isLoading: rateService.isLoading,
                refreshAction: {
                    Task { @MainActor in
                        await rateService.refresh()
                    }
                },
                quitAction: {
                    NSApplication.shared.terminate(nil)
                }
            )
        } label: {
            MenuBarLabel(snapshot: rateService.snapshot, isStale: rateService.isStale)
        }
    }
}
