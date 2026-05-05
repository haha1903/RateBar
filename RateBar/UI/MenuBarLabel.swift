import Foundation
import SwiftUI

/// Menu bar title for the current AUD to CNY exchange rate.
struct MenuBarLabel: View {
    let model: MenuBarLabelModel

    init(snapshot: RatesSnapshot?, isStale: Bool) {
        self.model = MenuBarLabelModel(snapshot: snapshot, isStale: isStale)
    }

    var body: some View {
        Label(model.title, systemImage: "dollarsign.circle")
            .labelStyle(.titleAndIcon)
            .monospacedDigit()
    }
}

/// Testable text model used by the compact menu bar label.
struct MenuBarLabelModel: Equatable, Sendable {
    let title: String

    init(snapshot: RatesSnapshot?, isStale: Bool) {
        let stalePrefix = isStale ? "⚠️ " : ""
        let base = snapshot?.base ?? RateDisplayFormatter.defaultBase

        guard let rate = snapshot?.rate(to: RateDisplayFormatter.primaryQuote) else {
            title = "\(stalePrefix)\(RateDisplayFormatter.pairString(base: base, quote: RateDisplayFormatter.primaryQuote)): --"
            return
        }

        title = "\(stalePrefix)\(RateDisplayFormatter.pairString(base: rate.base, quote: rate.quote)): \(RateDisplayFormatter.rateString(rate.value))"
    }
}

/// Shared formatting helpers for currency pairs, numeric rates, and menu timestamps.
enum RateDisplayFormatter {
    static let defaultBase = "AUD"
    static let primaryQuote = "CNY"
    static let quoteOrder = ["CNY", "USD", "JPY", "EUR"]

    static func pairString(base: String, quote: String) -> String {
        "\(base)→\(quote)"
    }

    static func rateString(_ value: Double) -> String {
        value.formatted(
            .number
                .precision(.fractionLength(2...4))
                .locale(Locale(identifier: "en_US_POSIX"))
        )
    }

    static func timeString(_ date: Date) -> String {
        date.formatted(.dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }
}
