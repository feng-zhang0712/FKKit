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
}
