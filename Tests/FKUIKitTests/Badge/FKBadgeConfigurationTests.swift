import FKUIKit
import XCTest

final class FKBadgeConfigurationTests: XCTestCase {
  func testInitClampsNegativeMaxDisplayCountToZero() {
    let configuration = FKBadgeConfiguration(maxDisplayCount: -10)

    XCTAssertEqual(configuration.maxDisplayCount, 0)
  }

  func testDefaultConfigurationUsesNinetyNinePlusOverflow() {
    let configuration = FKBadgeConfiguration()

    XCTAssertEqual(configuration.maxDisplayCount, 99)
    XCTAssertEqual(configuration.overflowSuffix, "+")
    XCTAssertEqual(configuration.dotDiameter, 8, accuracy: 0.001)
  }
}
