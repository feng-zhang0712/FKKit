import FKCoreKit
import XCTest

final class FKI18nMessageFormatTests: XCTestCase {
  func testInterpolateReplacesBraceTokens() {
    let result = FKI18nMessageFormat.interpolate(
      template: "Hello, {name}! You have {count} messages.",
      variables: ["name": "Ada", "count": "3"]
    )
    XCTAssertEqual(result, "Hello, Ada! You have 3 messages.")
  }

  func testInterpolateLeavesUnknownTokensUnchanged() {
    let result = FKI18nMessageFormat.interpolate(
      template: "Hi {name}, ref {unknown}",
      variables: ["name": "Bob"]
    )
    XCTAssertEqual(result, "Hi Bob, ref {unknown}")
  }

  func testFormatAppliesStringFormatWithLocale() {
    let result = FKI18nMessageFormat.format(
      "Hello %@",
      locale: Locale(identifier: "en_US"),
      arguments: ["World"]
    )
    XCTAssertEqual(result, "Hello World")
  }

  func testPluralSubstitutesCountForEnglishLocale() {
    let locale = Locale(identifier: "en_US")

    XCTAssertEqual(
      FKI18nMessageFormat.plural(format: "%d items", locale: locale, count: 0),
      "0 items"
    )
    XCTAssertEqual(
      FKI18nMessageFormat.plural(format: "%d items", locale: locale, count: 1),
      "1 items"
    )
    XCTAssertEqual(
      FKI18nMessageFormat.plural(format: "%d items", locale: locale, count: 42),
      "42 items"
    )
  }

  func testPluralUsesLocaleSpecificFormatString() {
    let english = FKI18nMessageFormat.plural(
      format: "%d items",
      locale: Locale(identifier: "en_US"),
      count: 3
    )
    let chinese = FKI18nMessageFormat.plural(
      format: "%d 项",
      locale: Locale(identifier: "zh-Hans"),
      count: 3
    )

    XCTAssertEqual(english, "3 items")
    XCTAssertEqual(chinese, "3 项")
  }

  func testPluralReturnsFormatUnchangedWhenCountIsOnlyLiteral() {
    let result = FKI18nMessageFormat.plural(
      format: "No items",
      locale: Locale(identifier: "en_US"),
      count: 5
    )

    XCTAssertEqual(result, "No items")
  }
}
