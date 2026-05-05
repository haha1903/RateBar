import Foundation

/// Centralizes user-facing localization keys used by the app and tests.
enum LocalizedStrings {
    static let refreshKey = "Refresh"
    static let refreshingKey = "Refreshing..."
    static let quitKey = "Quit"
    static let lastUpdatedKey = "Last updated: %@"
    static let staleDataKey = "Stale data"
    static let failedToRefreshKey = "Failed to refresh"

    static let localizationKeys = [
        refreshKey,
        refreshingKey,
        quitKey,
        lastUpdatedKey,
        staleDataKey,
        failedToRefreshKey,
    ]

    static var refresh: String {
        String(localized: "Refresh")
    }

    static var refreshing: String {
        String(localized: "Refreshing...")
    }

    static var quit: String {
        String(localized: "Quit")
    }

    static var staleData: String {
        String(localized: "Stale data")
    }

    /// Formats the localized last-updated menu row with the supplied time text.
    static func lastUpdated(_ timeText: String) -> String {
        String(format: String(localized: "Last updated: %@"), timeText)
    }

    /// Formats the localized refresh failure message while preserving error detail.
    static func failedToRefresh(_ error: any Error) -> String {
        "\(String(localized: "Failed to refresh")): \(error)"
    }
}
