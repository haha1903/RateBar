import Foundation

/// Decodable shape returned by the exchangerate.host latest-rates endpoint.
struct ExchangeRateHostResponse: Decodable {
    let base: String
    let date: String
    let rates: [String: Double]

    /// Converts the provider response into the app's snapshot model.
    func toSnapshot(fetchedAt: Date = Date()) -> RatesSnapshot {
        RatesSnapshot(base: base, fetchedAt: fetchedAt, rates: rates)
    }
}
