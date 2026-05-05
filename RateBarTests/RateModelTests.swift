@testable import RateBar
import XCTest

/// Tests for exchange-rate model decoding, lookup, and value equality.
final class RateModelTests: XCTestCase {
    private static let sampleJSON = """
    {
      "result": "success",
      "base_code": "AUD",
      "time_last_update_unix": 1777939351,
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

        XCTAssertEqual(response.result, "success")
        XCTAssertEqual(response.baseCode, "AUD")
        XCTAssertEqual(try XCTUnwrap(response.timeLastUpdateUnix), 1_777_939_351, accuracy: 0.5)
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

    private func decodeSampleResponse() throws -> OpenERAPIResponse {
        let data = try XCTUnwrap(Self.sampleJSON.data(using: .utf8))
        return try JSONDecoder().decode(OpenERAPIResponse.self, from: data)
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
