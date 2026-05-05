import AppIntents
import AppKit
import SwiftUI

/// Main application entry point for the RateBar menu bar utility.
@main
@MainActor
struct RateBarApp: App {
    @State private var rateService: RateService
    @State private var launchAtLogin: LaunchAtLogin
    private let refreshScheduler: RefreshScheduler

    init() {
        let service = RateService(client: OpenERAPIClient())
        let scheduler = RefreshScheduler(service: service)
        let loginService = LaunchAtLogin()

        _rateService = State(initialValue: service)
        _launchAtLogin = State(initialValue: loginService)
        refreshScheduler = scheduler

        if !ProcessInfo.processInfo.isRunningUnitTests {
            refreshScheduler.start()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent(
                snapshot: rateService.snapshot,
                lastError: rateService.lastError,
                isStale: rateService.isStale,
                isLoading: rateService.isLoading,
                isLaunchAtLoginEnabled: launchAtLogin.isEnabled,
                launchAtLoginError: launchAtLogin.lastError,
                refreshAction: {
                    Task { @MainActor in
                        await rateService.refresh()
                    }
                },
                setLaunchAtLoginEnabled: { isEnabled in
                    launchAtLogin.isEnabled = isEnabled
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

private extension ProcessInfo {
    /// Detects XCTest host launches so unit tests do not start production network refreshes.
    var isRunningUnitTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
    }
}
