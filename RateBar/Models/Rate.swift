import Foundation

/// A single exchange-rate quote from one base currency to one quote currency.
struct Rate: Codable, Equatable, Sendable {
    let base: String
    let quote: String
    let value: Double
}

/// A point-in-time collection of exchange rates for one base currency.
struct RatesSnapshot: Codable, Equatable, Sendable {
    let base: String
    let fetchedAt: Date
    let rates: [String: Double]

    /// Returns a typed quote for the requested currency when the snapshot contains it.
    func rate(to quote: String) -> Rate? {
        guard let value = rates[quote] else {
            return nil
        }

        return Rate(base: base, quote: quote, value: value)
    }
}
