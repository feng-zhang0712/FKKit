import FKCoreKit
import XCTest

final class FKI18nLocaleMatcherTests: XCTestCase {
  func testFallbackCandidatesProgressivelyBroadensLanguageCode() {
    let candidates = FKI18nLocaleMatcher.fallbackCandidates(for: "zh-Hans-CN")
    XCTAssertEqual(candidates, ["zh-Hans-CN", "zh-Hans", "zh"])
  }

  func testCanonicalizeMapsChineseRegionCodesToScript() {
    XCTAssertEqual(FKI18nLocaleMatcher.canonicalize("zh-CN"), "zh-Hans")
    XCTAssertEqual(FKI18nLocaleMatcher.canonicalize("zh-TW"), "zh-Hant")
  }

  func testBestSupportedLanguagePrefersPreferredMatch() {
    let resolved = FKI18nLocaleMatcher.bestSupportedLanguage(
      preferredLanguageCodes: ["zh-CN", "en"],
      supportedLanguageCodes: ["en", "zh-Hans"],
      fallback: "en"
    )
    XCTAssertEqual(resolved, "zh-Hans")
  }

  func testBestSupportedLanguageUsesFallbackWhenNoMatch() {
    let resolved = FKI18nLocaleMatcher.bestSupportedLanguage(
      preferredLanguageCodes: ["fr"],
      supportedLanguageCodes: ["en", "zh-Hans"],
      fallback: "en"
    )
    XCTAssertEqual(resolved, "en")
  }

  func testUniqueLanguageCodesPreservesOrderAndDeduplicates() {
    let unique = FKI18nLocaleMatcher.uniqueLanguageCodes(["en", "zh-CN", "en", "zh_CN"])
    XCTAssertEqual(unique, ["en", "zh-CN"])
  }
}
