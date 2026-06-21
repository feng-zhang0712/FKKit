@testable import FKUIKit
import XCTest

final class FKSearchTextNormalizationApplierTests: XCTestCase {
  func testNoneReturnsOriginalText() {
    XCTAssertEqual(
      FKSearchTextNormalizationApplier.apply(.none, to: "  hello  "),
      "  hello  "
    )
  }

  func testTrimWhitespaceAndNewlinesRemovesSurroundingWhitespace() {
    XCTAssertEqual(
      FKSearchTextNormalizationApplier.apply(.trimWhitespaceAndNewlines, to: "  hello\n"),
      "hello"
    )
  }

  func testCollapseInternalWhitespaceNormalizesRuns() {
    XCTAssertEqual(
      FKSearchTextNormalizationApplier.apply(.collapseInternalWhitespace, to: "  foo   bar \n baz "),
      "foo bar baz"
    )
  }

  func testMaxLengthTruncatesFromStart() {
    XCTAssertEqual(
      FKSearchTextNormalizationApplier.apply(.maxLength(4), to: "ABCDEF"),
      "ABCD"
    )
  }

  func testMaxLengthWithNegativeLimitReturnsOriginalText() {
    XCTAssertEqual(
      FKSearchTextNormalizationApplier.apply(.maxLength(-1), to: "ABCDEF"),
      "ABCDEF"
    )
  }

  func testMaxLengthZeroReturnsEmptyString() {
    XCTAssertEqual(
      FKSearchTextNormalizationApplier.apply(.maxLength(0), to: "ABC"),
      ""
    )
  }
}
