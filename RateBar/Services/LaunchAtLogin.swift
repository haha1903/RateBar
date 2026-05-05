import Foundation
import Observation
import ServiceManagement

/// Normalized launch-at-login states used by the app and tests.
enum LaunchAtLoginStatus: Equatable, Sendable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

/// Minimal abstraction over the system login-item service so registration can be tested.
@MainActor
protocol LaunchAtLoginServicing {
    var status: LaunchAtLoginStatus { get }

    func register() throws
    func unregister() throws
}

/// System-backed launch-at-login registrar for the main app bundle.
@MainActor
struct SystemLaunchAtLoginService: LaunchAtLoginServicing {
    var status: LaunchAtLoginStatus {
        LaunchAtLoginStatus(SMAppService.mainApp.status)
    }

    func register() throws {
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        try SMAppService.mainApp.unregister()
    }
}

/// Observable launch-at-login state used by the menu toggle.
@MainActor
@Observable
final class LaunchAtLogin {
    private(set) var status: LaunchAtLoginStatus
    var lastError: String?

    @ObservationIgnored private let service: any LaunchAtLoginServicing

    init(service: any LaunchAtLoginServicing = SystemLaunchAtLoginService()) {
        self.service = service
        self.status = service.status
    }

    /// True when the system reports that RateBar is registered to launch at login.
    var isEnabled: Bool {
        get {
            status == .enabled
        }
        set {
            refreshStatus()

            guard newValue != isEnabled else {
                return
            }

            do {
                if newValue {
                    try service.register()
                } else {
                    try service.unregister()
                }

                lastError = nil
            } catch {
                lastError = LocalizedStrings.launchAtLoginFailed(error)
            }

            refreshStatus()
        }
    }

    /// Reloads status from the underlying service, useful after external settings changes.
    func refreshStatus() {
        status = service.status
    }
}

private extension LaunchAtLoginStatus {
    init(_ status: SMAppService.Status) {
        switch status {
        case .notRegistered:
            self = .notRegistered
        case .enabled:
            self = .enabled
        case .requiresApproval:
            self = .requiresApproval
        case .notFound:
            self = .notFound
        @unknown default:
            self = .notFound
        }
    }
}
