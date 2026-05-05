@testable import RateBar
import XCTest

/// Smoke tests that prove the generated XCTest target is wired correctly.
final class SmokeTests: XCTestCase {
    func testAppCompiles() {
        XCTAssertTrue(true)
    }

    func testFinalSmoke() {
        let snapshot = RatesSnapshot(
            base: "AUD",
            fetchedAt: Date(timeIntervalSince1970: 1_777_932_000),
            rates: [
                "CNY": 4.72,
                "USD": 0.65,
                "JPY": 101.34,
                "EUR": 0.59,
            ]
        )
        let menuLabel = MenuBarLabelModel(snapshot: snapshot, isStale: false)
        let menuContent = MenuContentModel(snapshot: snapshot, lastError: nil, isStale: false)

        XCTAssertEqual(menuLabel.title, "AUD→CNY: 4.72")
        XCTAssertEqual(menuContent.rateRows.map(\.quote), ["CNY", "USD", "JPY", "EUR"])
        XCTAssertTrue(menuContent.rateRows.allSatisfy { $0.value != "--" })
    }
}
