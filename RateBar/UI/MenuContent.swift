import AppKit
import SwiftUI

/// Dropdown content shown when the user opens the RateBar menu bar extra.
struct MenuContent: View {
    let model: MenuContentModel
    let isLoading: Bool
    let refreshAction: @MainActor () -> Void
    let quitAction: @MainActor () -> Void

    init(
        snapshot: RatesSnapshot?,
        lastError: String?,
        isStale: Bool,
        isLoading: Bool,
        refreshAction: @escaping @MainActor () -> Void,
        quitAction: @escaping @MainActor () -> Void = { NSApplication.shared.terminate(nil) }
    ) {
        self.model = MenuContentModel(snapshot: snapshot, lastError: lastError, isStale: isStale)
        self.isLoading = isLoading
        self.refreshAction = refreshAction
        self.quitAction = quitAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 5) {
                ForEach(model.rateRows) { row in
                    GridRow {
                        Text(row.pair)
                        Text(row.value)
                            .monospacedDigit()
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }

            Divider()

            if model.isStale {
                Label(LocalizedStrings.staleData, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Text(model.lastUpdatedText)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let lastErrorText = model.lastErrorText {
                Text(lastErrorText)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }

            Divider()

            RefreshButton(isLoading: isLoading, action: refreshAction)

            Button(action: quitAction) {
                Label(LocalizedStrings.quit, systemImage: "power")
            }
        }
        .padding(.vertical, 6)
        .frame(minWidth: 220, alignment: .leading)
    }
}

/// A single rendered exchange-rate row in the dropdown.
struct RateRow: Equatable, Identifiable, Sendable {
    let base: String
    let quote: String
    let pair: String
    let value: String

    var id: String {
        quote
    }
}

/// Testable state model for the dropdown menu content.
struct MenuContentModel: Equatable, Sendable {
    let rateRows: [RateRow]
    let lastUpdatedText: String
    let lastErrorText: String?
    let isStale: Bool

    init(snapshot: RatesSnapshot?, lastError: String? = nil, isStale: Bool) {
        let base = snapshot?.base ?? RateDisplayFormatter.defaultBase

        self.rateRows = RateDisplayFormatter.quoteOrder.map { quote in
            let value = snapshot?
                .rate(to: quote)
                .map { RateDisplayFormatter.rateString($0.value) } ?? "--"

            return RateRow(
                base: base,
                quote: quote,
                pair: RateDisplayFormatter.pairString(base: base, quote: quote),
                value: value
            )
        }

        if let fetchedAt = snapshot?.fetchedAt {
            self.lastUpdatedText = LocalizedStrings.lastUpdated(RateDisplayFormatter.timeString(fetchedAt))
        } else {
            self.lastUpdatedText = LocalizedStrings.lastUpdated("--")
        }

        self.lastErrorText = lastError?.isEmpty == false ? lastError : nil
        self.isStale = isStale
    }
}

/// Refresh control shared by the dropdown and tests.
struct RefreshButton: View {
    let isLoading: Bool
    let action: @MainActor () -> Void

    var title: String {
        isLoading ? LocalizedStrings.refreshing : LocalizedStrings.refresh
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "arrow.clockwise")
        }
        .disabled(isLoading)
    }
}
