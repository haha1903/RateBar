@testable import RateBar
import XCTest

/// Tests for startup, recurring, and cancellable refresh scheduling.
final class RefreshSchedulerTests: XCTestCase {
    @MainActor
    func testStartTriggersImmediateRefresh() async {
        let client = CountingRateClient(snapshot: Self.makeSnapshot())
        let testDefaults = Self.makeDefaults()
        defer { Self.removeDefaults(testDefaults) }

        let service = RateService(client: client, defaults: testDefaults.defaults)
        let scheduler = RefreshScheduler(service: service, interval: 60)

        scheduler.start()
        let refreshCount = await Self.waitForRefreshCount(client, atLeast: 1)
        scheduler.stop()

        XCTAssertGreaterThanOrEqual(refreshCount, 1)
    }

    @MainActor
    func testStopCancelsTimer() async {
        let client = CountingRateClient(snapshot: Self.makeSnapshot())
        let testDefaults = Self.makeDefaults()
        defer { Self.removeDefaults(testDefaults) }

        let service = RateService(client: client, defaults: testDefaults.defaults)
        let scheduler = RefreshScheduler(service: service, interval: 0.1)

        scheduler.start()
        let countBeforeStop = await Self.waitForRefreshCount(client, atLeast: 1)
        scheduler.stop()
        try? await Task.sleep(nanoseconds: 250_000_000)

        let countAfterStop = await client.refreshCount()
        XCTAssertEqual(countAfterStop, countBeforeStop)
    }

    @MainActor
    func testIntervalRefresh() async {
        let client = CountingRateClient(snapshot: Self.makeSnapshot())
        let testDefaults = Self.makeDefaults()
        defer { Self.removeDefaults(testDefaults) }

        let service = RateService(client: client, defaults: testDefaults.defaults)
        let scheduler = RefreshScheduler(service: service, interval: 0.1)

        scheduler.start()
        let refreshCount = await Self.waitForRefreshCount(client, atLeast: 2, timeout: 1)
        scheduler.stop()

        XCTAssertGreaterThanOrEqual(refreshCount, 2)
    }

    private static func makeDefaults() -> TestDefaults {
        let suiteName = "RateBarSchedulerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return TestDefaults(suiteName: suiteName, defaults: defaults)
    }

    private static func removeDefaults(_ testDefaults: TestDefaults) {
        testDefaults.defaults.removePersistentDomain(forName: testDefaults.suiteName)
    }

    private static func waitForRefreshCount(
        _ client: CountingRateClient,
        atLeast expectedCount: Int,
        timeout: TimeInterval = 0.5
    ) async -> Int {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let refreshCount = await client.refreshCount()

            if refreshCount >= expectedCount {
                return refreshCount
            }

            try? await Task.sleep(nanoseconds: 20_000_000)
        }

        return await client.refreshCount()
    }

    private static func makeSnapshot(
        fetchedAt: Date = Date(timeIntervalSince1970: 1_777_932_000)
    ) -> RatesSnapshot {
        RatesSnapshot(
            base: "AUD",
            fetchedAt: fetchedAt,
            rates: [
                "CNY": 4.72,
                "USD": 0.65,
                "JPY": 101.34,
                "EUR": 0.59,
            ]
        )
    }
}

private struct TestDefaults {
    let suiteName: String
    let defaults: UserDefaults
}

private actor CountingRateClient: RateFetching {
    private let snapshot: RatesSnapshot
    private var count = 0

    init(snapshot: RatesSnapshot) {
        self.snapshot = snapshot
    }

    /// Records each fetch request and returns the configured snapshot.
    func fetch(base: String, symbols: [String]) async throws -> RatesSnapshot {
        count += 1
        return snapshot
    }

    /// Exposes the number of refreshes requested by the scheduler.
    func refreshCount() -> Int {
        count
    }
}
