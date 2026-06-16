import FKCoreKit
import XCTest

final class FKQRCodeParserTests: XCTestCase {
  func testParseReturnsURLForHTTPSString() {
    let payload = FKQRCodeParser.parse("https://example.com/path")
    guard case let .url(url) = payload else {
      XCTFail("Expected URL payload")
      return
    }
    XCTAssertEqual(url.absoluteString, "https://example.com/path")
  }

  func testParseReturnsTextForNonURLString() {
    let payload = FKQRCodeParser.parse("hello-fkkit")
    guard case let .text(value) = payload else {
      XCTFail("Expected text payload")
      return
    }
    XCTAssertEqual(value, "hello-fkkit")
  }

  func testParseReturnsUnknownForEmptyString() {
    let payload = FKQRCodeParser.parse("   ")
    guard case .unknown = payload else {
      XCTFail("Expected unknown payload")
      return
    }
  }

  func testParseTrimsWhitespaceBeforeClassification() {
    let payload = FKQRCodeParser.parse("  https://example.com  ")
    guard case let .url(url) = payload else {
      XCTFail("Expected URL payload")
      return
    }
    XCTAssertEqual(url.host, "example.com")
  }
}
