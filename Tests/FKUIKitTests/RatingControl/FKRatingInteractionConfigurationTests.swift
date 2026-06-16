import FKUIKit
import XCTest

final class FKRatingInteractionConfigurationTests: XCTestCase {
  func testMinimumTouchTargetClampedToAtLeastTwentyFourPoints() {
    let configuration = FKRatingInteractionConfiguration(
      minimumTouchTargetSize: CGSize(width: 10, height: 10)
    )

    XCTAssertEqual(configuration.minimumTouchTargetSize.width, 24, accuracy: 0.001)
    XCTAssertEqual(configuration.minimumTouchTargetSize.height, 24, accuracy: 0.001)
  }

  func testDisabledAlphaClampedIntoValidRange() {
    let low = FKRatingInteractionConfiguration(disabledAlpha: 0)
    let high = FKRatingInteractionConfiguration(disabledAlpha: 2)

    XCTAssertEqual(low.disabledAlpha, 0.1, accuracy: 0.001)
    XCTAssertEqual(high.disabledAlpha, 1, accuracy: 0.001)
  }
}
