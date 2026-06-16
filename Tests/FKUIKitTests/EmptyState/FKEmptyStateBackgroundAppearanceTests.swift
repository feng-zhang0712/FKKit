import FKUIKit
import XCTest

final class FKEmptyStateBackgroundAppearanceTests: XCTestCase {
  func testInitClampsBlockingOverlayAlphaIntoZeroToOneRange() {
    let configuration = FKEmptyStateBackgroundAppearance(blockingOverlayAlpha: 2)

    XCTAssertEqual(configuration.blockingOverlayAlpha, 1, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesOpaqueBackgroundWithoutGradient() {
    let configuration = FKEmptyStateBackgroundAppearance()

    XCTAssertTrue(configuration.gradientColors.isEmpty)
    XCTAssertEqual(configuration.blockingOverlayAlpha, 0, accuracy: 0.001)
  }
}
