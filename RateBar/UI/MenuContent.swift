import AppKit
import SwiftUI

/// Dropdown content shown when the user opens the RateBar menu bar extra.
struct MenuContent: View {
    let model: MenuContentModel
    let isLoading: Bool
    let isLaunchAtLoginEnabled: Bool
    let launchAtLoginError: String?
    let refreshAction: @MainActor () -> Void
    let setLaunchAtLoginEnabled: @MainActor (Bool) -> Void
    let quitAction: @MainActor () -> Void

    init(
        snapshot: RatesSnapshot?,
        lastError: String?,
        isStale: Bool,
        isLoading: Bool,
        isLaunchAtLoginEnabled: Bool = false,
        launchAtLoginError: String? = nil,
        refreshAction: @escaping @MainActor () -> Void,
        setLaunchAtLoginEnabled: @escaping @MainActor (Bool) -> Void = { _ in },
        quitAction: @escaping @MainActor () -> Void = { NSApplication.shared.terminate(nil) }
    ) {
        self.model = MenuContentModel(snapshot: snapshot, lastError: lastError, isStale: isStale)
        self.isLoading = isLoading
        self.isLaunchAtLoginEnabled = isLaunchAtLoginEnabled
        self.launchAtLoginError = launchAtLoginError
        self.refreshAction = refreshAction
        self.setLaunchAtLoginEnabled = setLaunchAtLoginEnabled
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

            LaunchAtLoginToggle(
                isEnabled: isLaunchAtLoginEnabled,
                setEnabled: setLaunchAtLoginEnabled
            )

            if let launchAtLoginError, !launchAtLoginError.isEmpty {
                Text(launchAtLoginError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }

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

/// Launch-at-login menu control shared by the dropdown and tests.
struct LaunchAtLoginToggle: View {
    let isEnabled: Bool
    let setEnabled: @MainActor (Bool) -> Void

    var title: String {
        LocalizedStrings.launchAtLogin
    }

    var body: some View {
        Toggle(
            isOn: Binding(
                get: {
                    isEnabled
                },
                set: { newValue in
                    setEnabled(newValue)
                }
            )
        ) {
            Label(title, systemImage: "power.circle")
        }
    }
}
