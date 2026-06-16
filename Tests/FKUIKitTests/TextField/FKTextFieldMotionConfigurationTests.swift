import FKUIKit
import XCTest

final class FKTextFieldMotionConfigurationTests: XCTestCase {
  func testInitClampsNegativeTransitionDurationToZero() {
    let configuration = FKTextFieldMotionConfiguration(transitionDuration: -0.4)

    XCTAssertEqual(configuration.transitionDuration, 0, accuracy: 0.001)
  }

  func testDefaultConfigurationEnablesMotionWithDefaultDuration() {
    let configuration = FKTextFieldMotionConfiguration()

    XCTAssertTrue(configuration.isEnabled)
    XCTAssertEqual(configuration.transitionDuration, 0.2, accuracy: 0.001)
  }
}
