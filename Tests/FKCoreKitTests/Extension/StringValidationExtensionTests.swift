import FKCoreKit
import XCTest

final class StringValidationExtensionTests: XCTestCase {
  func testIsValidEmailAcceptsCommonAddressShape() {
    XCTAssertTrue("user@example.com".fk_isValidEmail)
    XCTAssertFalse("not-an-email".fk_isValidEmail)
  }

  func testIsValidURLPatternAcceptsHTTPAndHTTPS() {
    XCTAssertTrue("https://example.com/path".fk_isValidURLPattern)
    XCTAssertTrue("http://example.com".fk_isValidURLPattern)
    XCTAssertFalse("ftp://example.com".fk_isValidURLPattern)
  }

  func testIsValidIPv4DetectsDottedQuads() {
    XCTAssertTrue("192.168.0.1".fk_isValidIPv4)
    XCTAssertFalse("999.999.999.999".fk_isValidIPv4)
  }

  func testReplacingMatchesSubstitutesPatternMatches() {
    let replaced = "order-123-done".fk_replacingMatches(pattern: "\\d+", with: "#")

    XCTAssertEqual(replaced, "order-#-done")
  }
}
