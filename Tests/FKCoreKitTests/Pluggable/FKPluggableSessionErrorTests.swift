import FKCoreKit
import XCTest

final class FKPluggableSessionErrorTests: XCTestCase {
  func testNotAuthenticatedProvidesLocalizedDescription() {
    let error = FKPluggableSessionError.notAuthenticated
    XCTAssertFalse(error.errorDescription?.isEmpty ?? true)
  }

  func testStorageFailureEmbedsUnderlyingDescription() {
    struct SampleError: LocalizedError {
      var errorDescription: String? { "disk full" }
    }

    let error = FKPluggableSessionError.storageFailure(underlying: SampleError())
    XCTAssertTrue(error.errorDescription?.contains("disk full") ?? false)
  }
}
