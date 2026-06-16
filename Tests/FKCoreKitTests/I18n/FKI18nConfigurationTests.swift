import FKCoreKit
import XCTest

final class FKI18nConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesEnglishAndPersistsSelection() {
    let configuration = FKI18nConfiguration.default

    XCTAssertEqual(configuration.defaultLanguageCode, FKI18nRecommendedLanguages.english)
    XCTAssertTrue(configuration.supportedLanguageCodes.contains(FKI18nRecommendedLanguages.english))
    XCTAssertTrue(configuration.persistSelection)
    XCTAssertTrue(configuration.enforceSupportedLanguages)
  }

  func testConfigurationStoresCustomLanguageListAndStorageKey() {
    let configuration = FKI18nConfiguration(
      defaultLanguageCode: "ja",
      supportedLanguageCodes: ["ja", "en"],
      fallbackLanguageCodes: ["en"],
      persistSelection: false,
      storageKey: "custom.language.key",
      enforceSupportedLanguages: false
    )

    XCTAssertEqual(configuration.defaultLanguageCode, "ja")
    XCTAssertEqual(configuration.supportedLanguageCodes, ["ja", "en"])
    XCTAssertEqual(configuration.fallbackLanguageCodes, ["en"])
    XCTAssertFalse(configuration.persistSelection)
    XCTAssertEqual(configuration.storageKey, "custom.language.key")
    XCTAssertFalse(configuration.enforceSupportedLanguages)
  }
}
