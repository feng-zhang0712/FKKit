import FKUIKit
import XCTest

final class FKListLoadingConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesSkeletonForInitialLoad() {
    let configuration = FKListLoadingConfiguration()

    XCTAssertTrue(configuration.usesSkeletonForInitialLoad)
    XCTAssertEqual(configuration.skeletonPolicy, .visibleCells)
  }

  func testConfigurationStoresCustomSkeletonPolicy() {
    let configuration = FKListLoadingConfiguration(
      usesSkeletonForInitialLoad: false,
      skeletonPolicy: .fullOverlay
    )

    XCTAssertFalse(configuration.usesSkeletonForInitialLoad)
    XCTAssertEqual(configuration.skeletonPolicy, .fullOverlay)
  }
}
