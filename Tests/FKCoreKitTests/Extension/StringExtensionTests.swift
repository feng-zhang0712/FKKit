import FKCoreKit
import XCTest

final class StringExtensionTests: XCTestCase {
  func testTrimmedRemovesLeadingAndTrailingWhitespace() {
    XCTAssertEqual("  hi  ".fk_trimmed, "hi")
    XCTAssertEqual("\n\t value \n".fk_trimmed, "value")
  }

  func testIsBlankTreatsWhitespaceOnlyAsBlank() {
    XCTAssertTrue("  ".fk_isBlank)
    XCTAssertTrue("\n".fk_isBlank)
    XCTAssertFalse("a".fk_isBlank)
    XCTAssertFalse(" a ".fk_isBlank)
  }

  func testNilIfEmptyReturnsNilForEmptyString() {
    XCTAssertNil("".fk_nilIfEmpty)
    XCTAssertEqual("x".fk_nilIfEmpty, "x")
  }

  func testNilIfBlankReturnsNilForBlankString() {
    XCTAssertNil("   ".fk_nilIfBlank)
    XCTAssertEqual("ok".fk_nilIfBlank, "ok")
  }

  func testSubstringReturnsEmptyWhenOutOfRange() {
    XCTAssertEqual("hello".fk_substring(location: 99, length: 1), "")
    XCTAssertEqual("hello".fk_substring(location: 0, length: 0), "")
  }

  func testSubstringReturnsPartialSuffixWhenLengthExceedsEnd() {
    XCTAssertEqual("hello".fk_substring(location: 3, length: 10), "lo")
  }

  func testLimitedPrefixClampsToMaxLength() {
    XCTAssertEqual("abcdef".fk_limitedPrefix(3), "abc")
    XCTAssertEqual("abc".fk_limitedPrefix(10), "abc")
    XCTAssertEqual("abc".fk_limitedPrefix(0), "")
  }

  func testMiddleTruncatedInsertsSeparatorWhenNeeded() {
    XCTAssertEqual(
      "A128839F210".fk_middleTruncated(prefixLength: 5, suffixLength: 3),
      "A1288…210"
    )
    XCTAssertEqual(
      "short".fk_middleTruncated(prefixLength: 2, suffixLength: 2),
      "short"
    )
  }

  func testAsURLWrapsURLStringInitializer() {
    XCTAssertEqual("https://example.com".fk_asURL?.absoluteString, "https://example.com")
    // `URL(string:)` percent-encodes spaces; the wrapper preserves Foundation behavior.
    XCTAssertEqual("not a url".fk_asURL?.absoluteString, "not%20a%20url")
  }
}
