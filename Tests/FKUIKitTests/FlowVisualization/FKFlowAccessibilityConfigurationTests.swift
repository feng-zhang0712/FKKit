import FKUIKit
import XCTest

final class FKFlowAccessibilityConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesStepAndTimelineLabelFormats() {
    let configuration = FKFlowAccessibilityConfiguration()

    XCTAssertTrue(configuration.stepLabelFormat.contains("{index}"))
    XCTAssertTrue(configuration.timelineLabelFormat.contains("{title}"))
    XCTAssertTrue(configuration.hidesConnectorsFromAccessibility)
  }

  func testConfigurationStoresCustomLabelAndHintOverrides() {
    let configuration = FKFlowAccessibilityConfiguration(
      customLabel: "Checkout progress",
      selectableHint: "Double tap to select step"
    )

    XCTAssertEqual(configuration.customLabel, "Checkout progress")
    XCTAssertEqual(configuration.selectableHint, "Double tap to select step")
  }
}
