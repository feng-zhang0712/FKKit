import FKCoreKit
import XCTest

private enum SampleError: Error {
  case sample
}

final class ErrorExtensionTests: XCTestCase {
  func testNSErrorBridgingExposesDomainCodeAndUserInfo() {
    let error = NSError(domain: "com.fkkit.test", code: 42, userInfo: ["key": "value"])

    XCTAssertEqual(error.fk_nsErrorDomain, "com.fkkit.test")
    XCTAssertEqual(error.fk_nsErrorCode, 42)
    XCTAssertEqual(error.fk_nsErrorUserInfo["key"] as? String, "value")
  }

  func testSwiftErrorBridgesToNSErrorMetadata() {
    let error: Error = SampleError.sample

    XCTAssertFalse(error.fk_nsErrorDomain.isEmpty)
  }
}
