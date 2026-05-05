@testable import RateBar
import XCTest

/// Tests for exchange-rate model decoding, lookup, and value equality.
final class RateModelTests: XCTestCase {
    private static let sampleJSON = """
    {
      "base": "AUD",
      "date": "2026-05-05",
      "rates": {
        "CNY": 4.72,
        "USD": 0.65,
        "JPY": 101.34,
        "EUR": 0.59
      }
    }
    """

    func testDecodeResponse() throws {
        let response = try decodeSampleResponse()
        let cnyRate = try XCTUnwrap(response.rates["CNY"])

        XCTAssertEqual(response.base, "AUD")
        XCTAssertEqual(response.date, "2026-05-05")
        XCTAssertEqual(response.rates.count, 4)
        XCTAssertEqual(cnyRate, 4.72, accuracy: 0.000_001)
    }

    func testRateLookup() {
        let snapshot = makeSnapshot()

        XCTAssertEqual(snapshot.rate(to: "CNY"), Rate(base: "AUD", quote: "CNY", value: 4.72))
        XCTAssertNil(snapshot.rate(to: "GBP"))
    }

    func testEquatable() {
        let first = makeSnapshot()
        let second = makeSnapshot()

        XCTAssertEqual(first, second)
    }

    private func decodeSampleResponse() throws -> ExchangeRateHostResponse {
        let data = try XCTUnwrap(Self.sampleJSON.data(using: .utf8))
        return try JSONDecoder().decode(ExchangeRateHostResponse.self, from: data)
    }

    private func makeSnapshot() -> RatesSnapshot {
        RatesSnapshot(
            base: "AUD",
            fetchedAt: Date(timeIntervalSince1970: 1_777_932_000),
            rates: [
                "CNY": 4.72,
                "USD": 0.65,
                "JPY": 101.34,
                "EUR": 0.59,
            ]
        )
    }
}
