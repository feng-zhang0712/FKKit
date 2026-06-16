import FKCoreKit
import XCTest

final class FKValueParsingTests: XCTestCase {
  func testIsNilOrEmptyDetectsBlankStringsAndEmptyCollections() {
    XCTAssertTrue(FKValueParsing.isNilOrEmpty(nil))
    XCTAssertTrue(FKValueParsing.isNilOrEmpty("   "))
    XCTAssertTrue(FKValueParsing.isNilOrEmpty([String]()))
    XCTAssertTrue(FKValueParsing.isNilOrEmpty(NSNull()))
    XCTAssertFalse(FKValueParsing.isNilOrEmpty("value"))
    XCTAssertFalse(FKValueParsing.isNilOrEmpty([1]))
  }

  func testStringFromCoercesNumbersAndPreservesStrings() {
    XCTAssertEqual(FKValueParsing.string(from: "hello"), "hello")
    XCTAssertEqual(FKValueParsing.string(from: NSNumber(value: 42)), "42")
    XCTAssertNil(FKValueParsing.string(from: nil))
  }

  func testIntAndDoubleParsingAcceptCommonJSONTypes() {
    XCTAssertEqual(FKValueParsing.int(from: 7), 7)
    XCTAssertEqual(FKValueParsing.int(from: "12"), 12)
    XCTAssertEqual(FKValueParsing.int(from: NSNumber(value: 3)), 3)
    XCTAssertNil(FKValueParsing.int(from: "abc"))

    XCTAssertEqual(FKValueParsing.double(from: 1.5), 1.5)
    XCTAssertEqual(FKValueParsing.double(from: "2.25"), 2.25)
    XCTAssertEqual(FKValueParsing.double(from: Float(0.5)) ?? 0, 0.5, accuracy: 0.001)
  }

  func testCatchingWrapsThrownErrors() {
    enum SampleError: Error { case failed }
    let success = FKValueParsing.catching { 42 }
    let failure = FKValueParsing.catching { throw SampleError.failed }

    XCTAssertEqual(try success.get(), 42)
    XCTAssertThrowsError(try failure.get()) { error in
      XCTAssertTrue(error is SampleError)
    }
  }
}
