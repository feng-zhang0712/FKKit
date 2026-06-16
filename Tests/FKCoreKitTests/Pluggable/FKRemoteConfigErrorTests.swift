import FKCoreKit
import XCTest

final class FKRemoteConfigErrorTests: XCTestCase {
  func testMissingSourceProvidesLocalizedDescription() {
    let error = FKRemoteConfigError.missingSource

    XCTAssertNotNil(error.errorDescription)
    XCTAssertFalse(error.errorDescription!.isEmpty)
  }

  func testFetchFailedEmbedsUnderlyingDescription() {
    struct Sample: LocalizedError {
      var errorDescription: String? { "network down" }
    }
    let error = FKRemoteConfigError.fetchFailed(underlying: Sample())

    XCTAssertTrue(error.errorDescription?.contains("network down") == true)
  }

  func testInvalidPayloadProvidesLocalizedDescription() {
    let error = FKRemoteConfigError.invalidPayload

    XCTAssertNotNil(error.errorDescription)
    XCTAssertFalse(error.errorDescription!.isEmpty)
  }
}
