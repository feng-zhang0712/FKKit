import FKCoreKit
import XCTest

final class FKI18nDictionaryLocalizerTests: XCTestCase {
  private var localizer: FKI18nDictionaryLocalizer!

  override func setUp() {
    super.setUp()
    localizer = FKI18nDictionaryLocalizer(
      flatDictionary: Fixtures.I18n.flatDictionary,
      initialLanguageCode: "en",
      fallbackLanguageCode: "en"
    )
  }

  override func tearDown() {
    localizer = nil
    super.tearDown()
  }

  func testLocalizedReturnsTranslationForActiveLanguage() {
    XCTAssertEqual(localizer.localized("welcome", table: nil, bundle: nil), "Welcome")
  }

  func testLocalizedInterpolatesVariables() {
    let value = localizer.localized("greeting", table: nil, variables: ["name": "Ada"])
    XCTAssertEqual(value, "Hello, Ada!")
  }

  func testSetLanguageCodeSwitchesActiveLanguage() {
    localizer.setLanguageCode("zh-Hans")
    XCTAssertEqual(localizer.currentLanguageCode, "zh-Hans")
    XCTAssertEqual(localizer.localized("welcome", table: nil, bundle: nil), "欢迎")
  }

  func testLocalizedFallsBackToFallbackLanguage() {
    localizer.setLanguageCode("fr")
    XCTAssertEqual(localizer.localized("welcome", table: nil, bundle: nil), "Welcome")
  }

  func testLocalizedReturnsKeyWhenMissingEverywhere() {
    XCTAssertEqual(localizer.localized("missing.key", table: nil, bundle: nil), "missing.key")
  }

  func testObserveLanguageChangeNotifiesOnSwitch() {
    let observedCodes = LockedStringCollector()

    let token = localizer.observeLanguageChange { language in
      observedCodes.append(language.code)
    }

    localizer.setLanguageCode("zh-Hans")
    token.invalidate()

    XCTAssertEqual(observedCodes.snapshot, ["en", "zh-Hans"])
  }

  func testLocalizedPluralAppliesCountToEnglishFormat() {
    XCTAssertEqual(localizer.localizedPlural("items.count", count: 0, table: nil), "0 items")
    XCTAssertEqual(localizer.localizedPlural("items.count", count: 1, table: nil), "1 items")
    XCTAssertEqual(localizer.localizedPlural("items.count", count: 12, table: nil), "12 items")
  }

  func testLocalizedPluralUsesActiveLanguageFormat() {
    localizer.setLanguageCode("zh-Hans")

    XCTAssertEqual(localizer.localizedPlural("items.count", count: 5, table: nil), "5 项")
    XCTAssertEqual(localizer.localizedPlural("items.none", count: 0, table: nil), "暂无项目")
  }

  func testLocalizedPluralReturnsKeyWhenMissingEverywhere() {
    XCTAssertEqual(localizer.localizedPlural("missing.plural", count: 2, table: nil), "missing.plural")
  }
}
