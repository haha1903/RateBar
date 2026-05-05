@testable import RateBar
import XCTest

/// Tests for cached observable rate state and refresh behavior.
final class RateServiceTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: SnapshotStore.defaultKey)
        super.tearDown()
    }

    @MainActor
    func testRefreshSuccess() async {
        let snapshot = Self.makeSnapshot()
        let client = MockRateClient(results: [.success(snapshot)])
        let testDefaults = makeDefaults()
        defer { removeDefaults(testDefaults) }

        let service = RateService(client: client, defaults: testDefaults.defaults)
        await service.refresh()

        let refreshedSnapshot = service.snapshot
        let lastError = service.lastError
        let isLoading = service.isLoading
        let requests = await client.requests()

        XCTAssertEqual(refreshedSnapshot, snapshot)
        XCTAssertNil(lastError)
        XCTAssertFalse(isLoading)
        XCTAssertEqual(requests, [MockRateRequest(base: "AUD", symbols: ["CNY", "USD", "JPY", "EUR"])])
    }

    @MainActor
    func testRefreshFailureKeepsCache() async {
        let cachedSnapshot = Self.makeSnapshot(value: 4.72)
        let client = MockRateClient(results: [
            .success(cachedSnapshot),
            .failure(MockRateError.refreshFailed),
        ])
        let testDefaults = makeDefaults()
        defer { removeDefaults(testDefaults) }

        let service = RateService(client: client, defaults: testDefaults.defaults)
        await service.refresh()
        await service.refresh()

        let snapshotAfterFailure = service.snapshot
        let lastError = service.lastError
        let isLoading = service.isLoading

        XCTAssertEqual(snapshotAfterFailure, cachedSnapshot)
        XCTAssertNotNil(lastError)
        XCTAssertFalse(isLoading)
    }

    @MainActor
    func testPersistAndReload() async {
        let snapshot = Self.makeSnapshot()
        let client = MockRateClient(results: [.success(snapshot)])
        let testDefaults = makeDefaults()
        defer { removeDefaults(testDefaults) }

        let service = RateService(client: client, defaults: testDefaults.defaults)
        await service.refresh()

        let reloadedService = RateService(
            client: MockRateClient(results: []),
            defaults: testDefaults.defaults
        )
        let reloadedSnapshot = reloadedService.snapshot

        XCTAssertEqual(reloadedSnapshot, snapshot)
    }

    @MainActor
    func testStaleAfterOneHour() async {
        let now = Date(timeIntervalSince1970: 1_777_940_000)
        let oldSnapshot = Self.makeSnapshot(fetchedAt: now.addingTimeInterval(-5_400))
        let testDefaults = makeDefaults()
        defer { removeDefaults(testDefaults) }
        try? SnapshotStore(defaults: testDefaults.defaults).save(oldSnapshot)

        let service = RateService(
            client: MockRateClient(results: []),
            defaults: testDefaults.defaults,
            currentDate: { now }
        )
        let isStale = service.isStale

        XCTAssertTrue(isStale)
    }

    private func makeDefaults() -> TestDefaults {
        let suiteName = "RateBarTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return TestDefaults(suiteName: suiteName, defaults: defaults)
    }

    private func removeDefaults(_ testDefaults: TestDefaults) {
        testDefaults.defaults.removePersistentDomain(forName: testDefaults.suiteName)
    }

    private static func makeSnapshot(
        value: Double = 4.72,
        fetchedAt: Date = Date(timeIntervalSince1970: 1_777_932_000)
    ) -> RatesSnapshot {
        RatesSnapshot(
            base: "AUD",
            fetchedAt: fetchedAt,
            rates: [
                "CNY": value,
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

private struct MockRateRequest: Equatable, Sendable {
    let base: String
    let symbols: [String]
}

private enum MockRateResult: Sendable {
    case success(RatesSnapshot)
    case failure(MockRateError)
}

private enum MockRateError: Error, Sendable {
    case refreshFailed
    case missingResult
}

private actor MockRateClient: RateFetching {
    private var results: [MockRateResult]
    private var recordedRequests: [MockRateRequest] = []

    init(results: [MockRateResult]) {
        self.results = results
    }

    /// Records the request and returns the next scripted result.
    func fetch(base: String, symbols: [String]) async throws -> RatesSnapshot {
        recordedRequests.append(MockRateRequest(base: base, symbols: symbols))

        guard !results.isEmpty else {
            throw MockRateError.missingResult
        }

        switch results.removeFirst() {
        case .success(let snapshot):
            return snapshot
        case .failure(let error):
            throw error
        }
    }

    /// Exposes captured requests for assertions without leaking actor state.
    func requests() -> [MockRateRequest] {
        recordedRequests
    }
}
