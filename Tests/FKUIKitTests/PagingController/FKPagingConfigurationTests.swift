import FKUIKit
import XCTest

final class FKPagingConfigurationTests: XCTestCase {
  func testInitClampsNegativeSpacingAndPreloadRange() {
    let configuration = FKPagingConfiguration(
      interPageSpacing: -12,
      preloadRange: -3
    )

    XCTAssertEqual(configuration.interPageSpacing, 0, accuracy: 0.001)
    XCTAssertEqual(configuration.preloadRange, 0)
  }

  func testDefaultConfigurationEnablesSwipePagingWithNearRetention() {
    let configuration = FKPagingConfiguration()

    XCTAssertTrue(configuration.allowsSwipePaging)
    XCTAssertEqual(configuration.pageSwitchGate, .immediate)
    XCTAssertEqual(configuration.retentionPolicy, .keepNear(distance: 1))
    XCTAssertEqual(configuration.tabBarPlacement, .contentTop)
  }
}
