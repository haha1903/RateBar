import Foundation
import Observation

/// Observable exchange-rate state used by the menu bar UI and refresh scheduler.
@MainActor
@Observable
final class RateService {
    var snapshot: RatesSnapshot?
    var lastError: String?
    var isLoading = false

    @ObservationIgnored private var client: any RateFetching
    @ObservationIgnored private var store: SnapshotStore
    @ObservationIgnored private var base: String
    @ObservationIgnored private var symbols: [String]
    @ObservationIgnored private var staleInterval: TimeInterval
    @ObservationIgnored private var currentDate: () -> Date

    init(
        client: any RateFetching,
        defaults: UserDefaults = .standard,
        base: String = "AUD",
        symbols: [String] = ["CNY", "USD", "JPY", "EUR"],
        staleInterval: TimeInterval = 3_600,
        currentDate: @escaping () -> Date = Date.init
    ) {
        self.client = client
        self.store = SnapshotStore(defaults: defaults)
        self.base = base
        self.symbols = symbols
        self.staleInterval = staleInterval
        self.currentDate = currentDate
        self.snapshot = store.load()
    }

    /// The timestamp of the most recent successful refresh, if any.
    var lastSuccessfulRefresh: Date? {
        snapshot?.fetchedAt
    }

    /// Returns true when cached data is older than the configured stale interval.
    var isStale: Bool {
        guard let snapshot else {
            return false
        }

        return currentDate().timeIntervalSince(snapshot.fetchedAt) > staleInterval
    }

    /// Fetches rates, updates observable state, and persists successful results.
    func refresh() async {
        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        do {
            let freshSnapshot = try await client.fetch(base: base, symbols: symbols)
            snapshot = freshSnapshot
            try store.save(freshSnapshot)
        } catch {
            lastError = "Failed to refresh: \(error)"
        }
    }
}
