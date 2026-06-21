import FKCoreKit
import XCTest

final class FKI18nManagerTests: XCTestCase {
  private let suiteName = "FKI18nManagerTests.\(UUID().uuidString)"
  private var defaults: UserDefaults!
  private var manager: FKI18nManager!
  private var translator: FKI18nStaticDictionaryTranslator!

  override func setUp() {
    super.setUp()
    defaults = UserDefaults(suiteName: suiteName)!
    translator = FKI18nStaticDictionaryTranslator(
      flatDictionary: Fixtures.I18n.flatDictionary,
      fallbackLanguageCode: "en"
    )
    manager = FKI18nManager(
      configuration: FKI18nConfiguration(
        defaultLanguageCode: "en",
        supportedLanguageCodes: ["en", "zh-Hans"],
        persistSelection: false,
        storageKey: "test.language",
        enforceSupportedLanguages: false
      ),
      userDefaults: defaults
    )
    manager.setDictionaryTranslator(translator)
    manager.setLanguageCode("en")
  }

  override func tearDown() {
    manager = nil
    translator = nil
    defaults.removePersistentDomain(forName: suiteName)
    defaults = nil
    super.tearDown()
  }

  func testLocalizedUsesDictionaryTranslatorBeforeBundleLookup() {
    XCTAssertEqual(manager.localized("welcome", table: nil), "Welcome")
  }

  func testLocalizedInterpolatesVariablesThroughTranslator() {
    let value = manager.localized("greeting", table: nil, variables: ["name": "Ada"])

    XCTAssertEqual(value, "Hello, Ada!")
  }

  func testLocalizedPluralAppliesCountThroughTranslator() {
    XCTAssertEqual(manager.localizedPlural("items.count", count: 4, table: nil), "4 items")
  }

  func testSetLanguageCodeUpdatesCurrentLanguageAndLocalizedPlural() {
    manager.setLanguageCode("zh-Hans")

    XCTAssertEqual(manager.currentLanguageCode, "zh-Hans")
    XCTAssertEqual(manager.localizedPlural("items.count", count: 2, table: nil), "2 项")
  }

  func testLocalizedReturnsKeyWhenMissingEverywhere() {
    XCTAssertEqual(manager.localized("missing.manager.key", table: nil), "missing.manager.key")
  }

  func testObserveLanguageChangeNotifiesAfterSetLanguageCode() {
    let observedCodes = LockedStringCollector()

    let token = manager.observeLanguageChange { language in
      observedCodes.append(language.code)
    }

    manager.setLanguageCode("zh-Hans")
    token.invalidate()

    XCTAssertEqual(observedCodes.snapshot, ["en", "zh-Hans"])
  }
}
