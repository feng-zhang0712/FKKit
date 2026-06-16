import FKUIKit
import XCTest

final class FKFlowMotionConfigurationTests: XCTestCase {
  func testInitClampsNegativeAnimationDurationToZero() {
    let configuration = FKFlowMotionConfiguration(animationDuration: -1)

    XCTAssertEqual(configuration.animationDuration, 0, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesDefaultTimingAndPulsesCurrentNode() {
    let configuration = FKFlowMotionConfiguration()

    XCTAssertEqual(configuration.timing, .default)
    XCTAssertTrue(configuration.respectsReducedMotion)
    XCTAssertTrue(configuration.pulsesCurrentNode)
  }
}
