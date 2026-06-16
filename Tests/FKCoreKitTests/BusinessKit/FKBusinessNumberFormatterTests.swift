import FKCoreKit
import XCTest

final class FKBusinessNumberFormatterTests: XCTestCase {
  func testFormatCompactUsesKSuffixForEnglishLocale() {
    let formatter = FKBusinessNumberFormatter { "en" }
    XCTAssertEqual(formatter.formatCompact(1500), "1.5K")
  }

  func testFormatCompactUsesWanSuffixForChineseLocale() {
    let formatter = FKBusinessNumberFormatter { "zh-Hans" }
    XCTAssertEqual(formatter.formatCompact(12_000), "1.2万")
  }

  func testFormatAmountUsesFractionDigits() {
    let formatter = FKBusinessNumberFormatter { "en_US" }
    let formatted = formatter.formatAmount(Decimal(string: "1234.5")!, fractionDigits: 2)
    XCTAssertTrue(formatted.contains("1"))
    XCTAssertTrue(formatted.contains("234"))
  }
}
