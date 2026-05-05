# RateBar

RateBar is a macOS menu bar exchange-rate utility. The MVP will show AUD to CNY in the menu bar and expose AUD to USD, JPY, and EUR in the menu. This first project skeleton contains a minimal `MenuBarExtra` app and an XCTest smoke test.

## Requirements

- macOS 26 Tahoe or later
- Xcode 26 or later with Swift 6
- XcodeGen

Install XcodeGen with Homebrew:

```sh
brew install xcodegen
```

## Build

Generate the Xcode project, then build the app:

```sh
xcodegen generate
xcodebuild -scheme RateBar -destination "platform=macOS,arch=$(uname -m)" build
```

## Test

Run the XCTest suite:

```sh
xcodebuild -scheme RateBar -destination "platform=macOS,arch=$(uname -m)" test
```

## Run

Open the generated project and run the `RateBar` scheme from Xcode. In the T01 skeleton, the menu bar extra displays the `RateBar` title and a placeholder `Hello` menu item.
