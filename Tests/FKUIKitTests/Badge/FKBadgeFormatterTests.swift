import FKUIKit
import XCTest

final class FKBadgeFormatterTests: XCTestCase {
  private let configuration = FKBadgeConfiguration(maxDisplayCount: 99, overflowSuffix: "+")

  func testDisplayStringReturnsNilForNonPositiveCounts() {
    XCTAssertNil(FKBadgeFormatter.displayString(count: 0, configuration: configuration))
    XCTAssertNil(FKBadgeFormatter.displayString(count: -3, configuration: configuration))
  }

  func testDisplayStringReturnsPlainNumberWithinLimit() {
    XCTAssertEqual(FKBadgeFormatter.displayString(count: 7, configuration: configuration), "7")
    XCTAssertEqual(FKBadgeFormatter.displayString(count: 99, configuration: configuration), "99")
  }

  func testDisplayStringUsesOverflowSuffixAboveMaxDisplayCount() {
    XCTAssertEqual(FKBadgeFormatter.displayString(count: 100, configuration: configuration), "99+")
    XCTAssertEqual(FKBadgeFormatter.displayString(count: 1_000, configuration: configuration), "99+")
  }

  func testParseNonNegativeCountAcceptsDigitsAndRejectsInvalidInput() {
    XCTAssertEqual(FKBadgeFormatter.parseNonNegativeCount("42"), 42)
    XCTAssertEqual(FKBadgeFormatter.parseNonNegativeCount("  7  "), 7)
    XCTAssertNil(FKBadgeFormatter.parseNonNegativeCount(""))
    XCTAssertNil(FKBadgeFormatter.parseNonNegativeCount("12a"))
    XCTAssertNil(FKBadgeFormatter.parseNonNegativeCount("-1"))
  }
}
