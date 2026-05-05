@testable import RateBar
import XCTest

/// Tests for the menu bar label and dropdown display models.
final class MenuContentTests: XCTestCase {
    func testMenuContentRendersFourRates() {
        let model = MenuContentModel(snapshot: Self.makeSnapshot(), isStale: false)

        XCTAssertEqual(model.rateRows.count, 4)
        XCTAssertEqual(model.rateRows.map(\.pair), ["AUD→CNY", "AUD→USD", "AUD→JPY", "AUD→EUR"])
        XCTAssertEqual(model.rateRows.map(\.value), ["4.72", "0.65", "101.34", "0.59"])
    }

    func testStaleBadgeAppears() {
        let model = MenuBarLabelModel(snapshot: Self.makeSnapshot(), isStale: true)

        XCTAssertTrue(model.title.hasPrefix("⚠️ "))
        XCTAssertTrue(model.title.contains("AUD→CNY: 4.72"))
    }

    @MainActor
    func testRefreshButtonInvokesService() {
        let spy = RefreshSpy()
        let button = RefreshButton(isLoading: false, action: spy.refresh)

        button.action()

        XCTAssertEqual(spy.refreshCount, 1)
        XCTAssertEqual(button.title, "Refresh")
    }

    @MainActor
    func testRefreshButtonShowsLoadingState() {
        let button = RefreshButton(isLoading: true, action: {})

        XCTAssertEqual(button.title, "Refreshing...")
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

@MainActor
private final class RefreshSpy {
    private(set) var refreshCount = 0

    /// Records one refresh request from the menu button.
    func refresh() {
        refreshCount += 1
    }
}
