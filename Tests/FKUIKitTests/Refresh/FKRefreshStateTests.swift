import FKUIKit
import XCTest

final class FKRefreshStateTests: XCTestCase {
  func testFailedStatesCompareEqualRegardlessOfErrorPayload() {
    XCTAssertEqual(FKRefreshState.failed(NSError(domain: "a", code: 1)), FKRefreshState.failed(nil))
  }

  func testPullingProgressMustMatchForEquality() {
    XCTAssertEqual(FKRefreshState.pulling(progress: 0.5), FKRefreshState.pulling(progress: 0.5))
    XCTAssertNotEqual(FKRefreshState.pulling(progress: 0.2), FKRefreshState.pulling(progress: 0.8))
  }

  func testIdleIsDistinctFromRefreshing() {
    XCTAssertNotEqual(FKRefreshState.idle, FKRefreshState.refreshing)
  }
}
