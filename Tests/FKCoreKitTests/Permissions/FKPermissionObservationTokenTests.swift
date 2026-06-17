@testable import FKCoreKit
import XCTest

#if os(iOS)
final class FKPermissionObservationTokenTests: XCTestCase {
  func testInvalidateInvokesCancelClosureOnce() {
    var cancelCount = 0
    let token = FKPermissionObservationToken {
      cancelCount += 1
    }

    token.invalidate()
    token.invalidate()

    XCTAssertEqual(cancelCount, 1)
  }

  func testDeinitInvokesCancelClosureWhenNotInvalidatedExplicitly() {
    var cancelCount = 0
    autoreleasepool {
      _ = FKPermissionObservationToken {
        cancelCount += 1
      }
    }

    XCTAssertEqual(cancelCount, 1)
  }
}
#endif
