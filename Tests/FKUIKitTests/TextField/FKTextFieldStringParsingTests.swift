@testable import FKUIKit
import XCTest

final class FKTextFieldStringParsingTests: XCTestCase {
  func testDigitsOnlyFiltersNonNumericCharacters() {
    XCTAssertEqual("a1b-2 3".fk_digitsOnly, "123")
  }

  func testLettersOnlyKeepsAsciiLetters() {
    XCTAssertEqual("A1b2C".fk_lettersOnly, "AbC")
  }

  func testAlphaNumericOnlyKeepsAsciiLettersAndNumbers() {
    XCTAssertEqual("A1!b_2".fk_alphaNumericOnly, "A1b2")
  }

  func testContainsEmojiIgnoresAsciiDigits() {
    XCTAssertFalse("12345".fk_containsEmoji)
  }

  func testContainsEmojiDetectsEmojiScalars() {
    XCTAssertTrue("Hello 👋".fk_containsEmoji)
  }

  func testGroupedAppliesPatternWithRepeatingLastGroup() {
    XCTAssertEqual("1234567890".fk_grouped(separator: "-", pattern: [3, 2]), "123-45-67-89-0")
  }

  func testGroupedReturnsOriginalWhenPatternEmpty() {
    XCTAssertEqual("12345".fk_grouped(pattern: []), "12345")
  }

  func testTruncatedReturnsEmptyForNegativeLimit() {
    XCTAssertEqual("hello".fk_truncated(to: -1), "")
  }

  func testTruncatedReturnsOriginalWhenWithinLimit() {
    XCTAssertEqual("hello".fk_truncated(to: 10), "hello")
  }

  func testTruncatedClipsToMaximumCount() {
    XCTAssertEqual("hello".fk_truncated(to: 3), "hel")
  }
}
