import FKUIKit
import XCTest

final class FKRatingMotionConfigurationTests: XCTestCase {
  func testInitClampsNegativeAnimationDurationToZero() {
    let configuration = FKRatingMotionConfiguration(animationDuration: -0.5)

    XCTAssertEqual(configuration.animationDuration, 0, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesDefaultTimingAndReducedMotionRespect() {
    let configuration = FKRatingMotionConfiguration()

    XCTAssertEqual(configuration.timing, .default)
    XCTAssertTrue(configuration.respectsReducedMotion)
    XCTAssertEqual(configuration.selectionAnimation, .bounce)
  }
}
