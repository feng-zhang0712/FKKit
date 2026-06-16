import FKUIKit
import XCTest

final class FKProgressBarMotionConfigurationTests: XCTestCase {
  func testInitClampsNegativeAnimationDurationToZero() {
    let configuration = FKProgressBarMotionConfiguration(animationDuration: -1)

    XCTAssertEqual(configuration.animationDuration, 0, accuracy: 0.001)
  }

  func testInitClampsSpringDampingAndIndeterminatePeriod() {
    let configuration = FKProgressBarMotionConfiguration(
      springDampingRatio: 0,
      indeterminatePeriod: 0.05
    )

    XCTAssertEqual(configuration.springDampingRatio, 0.01, accuracy: 0.001)
    XCTAssertEqual(configuration.indeterminatePeriod, 0.2, accuracy: 0.001)
  }
}
