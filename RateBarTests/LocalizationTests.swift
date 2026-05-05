@testable import RateBar
import XCTest

/// Tests that the string catalog contains the required English and Chinese localizations.
final class LocalizationTests: XCTestCase {
    func testLocalizationKeysExist() throws {
        let catalog = try Self.loadStringCatalog()

        for key in LocalizedStrings.localizationKeys {
            let localizations = try XCTUnwrap(catalog[key], "Missing catalog key: \(key)")

            for language in ["en", "zh-Hans"] {
                let value = try XCTUnwrap(
                    localizations[language],
                    "Missing \(language) translation for \(key)"
                )
                XCTAssertFalse(value.isEmpty, "Empty \(language) translation for \(key)")
            }
        }
    }

    func testChineseTranslation() throws {
        let chineseBundle = try Self.localizedBundle(language: "zh-Hans")
        let translatedRefresh = chineseBundle.localizedString(
            forKey: LocalizedStrings.refreshKey,
            value: nil,
            table: nil
        )

        XCTAssertEqual(translatedRefresh, "刷新")
    }

    private static func localizedBundle(language: String) throws -> Bundle {
        let path = try XCTUnwrap(
            Bundle.main.path(forResource: language, ofType: "lproj"),
            "Missing compiled \(language) localization bundle"
        )
        return try XCTUnwrap(Bundle(path: path), "Unable to load \(language) localization bundle")
    }

    private static func loadStringCatalog() throws -> [String: [String: String]] {
        let catalogURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("RateBar/Localizable.xcstrings")
        let data = try Data(contentsOf: catalogURL)
        let object = try JSONSerialization.jsonObject(with: data)
        let root = try XCTUnwrap(object as? [String: Any])
        let strings = try XCTUnwrap(root["strings"] as? [String: Any])

        return strings.reduce(into: [String: [String: String]]()) { result, entry in
            guard
                let entryBody = entry.value as? [String: Any],
                let localizations = entryBody["localizations"] as? [String: Any]
            else {
                return
            }

            result[entry.key] = localizations.reduce(into: [String: String]()) { localizedValues, localization in
                guard
                    let localizationBody = localization.value as? [String: Any],
                    let stringUnit = localizationBody["stringUnit"] as? [String: Any],
                    let value = stringUnit["value"] as? String
                else {
                    return
                }

                localizedValues[localization.key] = value
            }
        }
    }
}
