import FKCoreKit
import XCTest

final class ResultExtensionTests: XCTestCase {
  func testSuccessValueReturnsWrappedValue() {
    let ok = Result<Int, NSError>.success(1)
    XCTAssertEqual(ok.fk_successValue, 1)
    XCTAssertNil(ok.fk_failureValue)
  }

  func testFailureValueReturnsWrappedError() {
    let err = Result<Int, NSError>.failure(NSError(domain: "t", code: 1))
    XCTAssertNil(err.fk_successValue)
    XCTAssertNotNil(err.fk_failureValue)
  }
}
