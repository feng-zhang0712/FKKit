import FKUIKit
import XCTest

final class FKAvatarStoryRingConfigurationTests: XCTestCase {
  func testInitClampsWidthAndPaddingToMinimumValues() {
    let configuration = FKAvatarStoryRingConfiguration(width: 0.5, padding: -2)

    XCTAssertEqual(configuration.width, 1, accuracy: 0.001)
    XCTAssertEqual(configuration.padding, 0, accuracy: 0.001)
  }

  func testInitUsesFallbackGradientWhenColorsAreEmpty() {
    let configuration = FKAvatarStoryRingConfiguration(gradientColors: [])

    XCTAssertEqual(configuration.gradientColors.count, 2)
  }
}
