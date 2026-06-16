import FKUIKit
import XCTest

final class FKButtonLoadingIndicatorConfigurationTests: XCTestCase {
  func testInitClampsScaleIntoSupportedRange() {
    let tooSmall = FKButtonLoadingIndicatorConfiguration(scale: 0.1)
    let tooLarge = FKButtonLoadingIndicatorConfiguration(scale: 5)

    XCTAssertEqual(tooSmall.scale, 0.5, accuracy: 0.001)
    XCTAssertEqual(tooLarge.scale, 3, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesMediumStyleAndUnitScale() {
    let configuration = FKButtonLoadingIndicatorConfiguration.default

    XCTAssertEqual(configuration.style, .medium)
    XCTAssertEqual(configuration.scale, 1, accuracy: 0.001)
    XCTAssertNil(configuration.color)
  }
}
