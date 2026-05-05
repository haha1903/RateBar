import Foundation

/// Decodable shape returned by the open.er-api.com latest-rates endpoint.
///
/// Example: `https://open.er-api.com/v6/latest/AUD`
/// ```
/// {
///   "result": "success",
///   "base_code": "AUD",
///   "time_last_update_unix": 1777939351,
///   "rates": { "CNY": 4.71, "USD": 0.65, ... }
/// }
/// ```
struct OpenERAPIResponse: Decodable, Sendable {
    let result: String
    let baseCode: String
    let timeLastUpdateUnix: TimeInterval?
    let rates: [String: Double]

    enum CodingKeys: String, CodingKey {
        case result
        case baseCode = "base_code"
        case timeLastUpdateUnix = "time_last_update_unix"
        case rates
    }

    /// Converts the provider response into the app's snapshot model.
    func toSnapshot(fetchedAt: Date = Date()) -> RatesSnapshot {
        RatesSnapshot(base: baseCode, fetchedAt: fetchedAt, rates: rates)
    }
}
