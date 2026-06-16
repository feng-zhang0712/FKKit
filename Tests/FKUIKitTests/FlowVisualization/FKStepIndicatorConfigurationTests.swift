import FKUIKit
import XCTest

final class FKStepIndicatorConfigurationTests: XCTestCase {
  func testDefaultConfigurationComposesNestedFlowConfigurations() {
    let configuration = FKStepIndicatorConfiguration()

    XCTAssertEqual(configuration.layout.layout, .horizontalTopLabels)
    XCTAssertFalse(configuration.interaction.allowsSelection)
    XCTAssertEqual(configuration.motion.timing, .default)
  }

  func testConfigurationStoresCustomStepSpacing() {
    var configuration = FKStepIndicatorConfiguration()
    configuration.layout.stepSpacing = 16

    XCTAssertEqual(configuration.layout.stepSpacing, 16, accuracy: 0.001)
  }
}
