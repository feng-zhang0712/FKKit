import FKUIKit
import XCTest

final class FKStepIndicatorLayoutConfigurationTests: XCTestCase {
  func testInitClampsSpacingAndLineLimits() {
    let configuration = FKStepIndicatorLayoutConfiguration(
      stepSpacing: -4,
      maxVisibleSteps: -2,
      titleNumberOfLines: 0,
      subtitleNumberOfLines: -1
    )

    XCTAssertEqual(configuration.stepSpacing, 0, accuracy: 0.001)
    XCTAssertEqual(configuration.maxVisibleSteps, 0)
    XCTAssertEqual(configuration.titleNumberOfLines, 1)
    XCTAssertEqual(configuration.subtitleNumberOfLines, 1)
  }

  func testDefaultLayoutUsesHorizontalTopLabels() {
    let configuration = FKStepIndicatorLayoutConfiguration()

    XCTAssertEqual(configuration.layout, .horizontalTopLabels)
    XCTAssertFalse(configuration.showsPartialConnectorFill)
  }
}
