import FKCoreKit
import XCTest

final class FKMockReachabilityTests: XCTestCase {
  func testIsReachableReflectsConfiguredValue() {
    let online = FKMockReachability(isReachable: true)
    let offline = FKMockReachability(isReachable: false)

    XCTAssertTrue(online.isReachable)
    XCTAssertFalse(offline.isReachable)
  }
}
