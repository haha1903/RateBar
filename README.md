# RateBar

RateBar is a macOS menu bar exchange-rate utility. The MVP shows AUD to CNY in the menu bar and exposes AUD to CNY, USD, JPY, and EUR in the dropdown menu.

## Screenshot

![RateBar menu showing AUD exchange rates and refresh controls](docs/ratebar-menu-screenshot.svg)

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

Open the generated project and run the `RateBar` scheme from Xcode. The menu bar extra displays `AUD→CNY` as the compact title; opening it shows the four configured AUD exchange-rate pairs, the last successful refresh time, Refresh, and Quit.
