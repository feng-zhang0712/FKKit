import FKCoreKit
import XCTest

final class FKHTTPMethodTests: XCTestCase {
  func testRawValuesMatchStandardHTTPVerbs() {
    XCTAssertEqual(FKHTTPMethod.get.rawValue, "GET")
    XCTAssertEqual(FKHTTPMethod.post.rawValue, "POST")
    XCTAssertEqual(FKHTTPMethod.delete.rawValue, "DELETE")
  }

  func testAllCasesIncludeHeadAndPatch() {
    XCTAssertTrue(FKHTTPMethod.allCases.contains(.head))
    XCTAssertTrue(FKHTTPMethod.allCases.contains(.patch))
  }
}
