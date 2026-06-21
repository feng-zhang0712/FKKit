@testable import FKUIKit
import XCTest

final class FKJavaScriptMessageBodyConverterTests: XCTestCase {
  func testConvertNilToNullBody() {
    XCTAssertEqual(FKJavaScriptMessageBodyConverter.convert(nil), .null)
  }

  func testConvertBoolAndStringPrimitives() {
    XCTAssertEqual(FKJavaScriptMessageBodyConverter.convert(true), .bool(true))
    XCTAssertEqual(FKJavaScriptMessageBodyConverter.convert("hello"), .string("hello"))
  }

  func testConvertIntegerAndDouble() {
    XCTAssertEqual(FKJavaScriptMessageBodyConverter.convert(42), .int(42))
    XCTAssertEqual(FKJavaScriptMessageBodyConverter.convert(1.5), .double(1.5))
  }

  func testConvertNSNumberBooleanBox() {
    let value = NSNumber(value: true)

    XCTAssertEqual(FKJavaScriptMessageBodyConverter.convert(value), .bool(true))
  }

  func testConvertNSNumberNumericBox() {
    let value = NSNumber(value: 3.25)

    if case let .double(number) = FKJavaScriptMessageBodyConverter.convert(value) {
      XCTAssertEqual(number, 3.25, accuracy: 0.001)
    } else {
      XCTFail("Expected double body")
    }
  }

  func testConvertArrayRecursively() {
    let body = FKJavaScriptMessageBodyConverter.convert([1, "two", true])

    if case let .array(values) = body {
      XCTAssertEqual(values.count, 3)
      XCTAssertEqual(values[0], .int(1))
      XCTAssertEqual(values[1], .string("two"))
      XCTAssertEqual(values[2], .bool(true))
    } else {
      XCTFail("Expected array body")
    }
  }

  func testConvertDictionaryRecursively() {
    let body = FKJavaScriptMessageBodyConverter.convert(["count": 2, "ready": true])

    if case let .dictionary(values) = body {
      XCTAssertEqual(values["count"], .int(2))
      XCTAssertEqual(values["ready"], .bool(true))
    } else {
      XCTFail("Expected dictionary body")
    }
  }

  func testConvertUnknownValueFallsBackToStringDescription() {
    struct Token {}

    if case let .string(text) = FKJavaScriptMessageBodyConverter.convert(Token()) {
      XCTAssertFalse(text.isEmpty)
    } else {
      XCTFail("Expected string fallback")
    }
  }
}
