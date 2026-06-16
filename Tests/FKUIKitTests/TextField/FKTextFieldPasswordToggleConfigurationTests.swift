import FKUIKit
import XCTest

final class FKTextFieldPasswordToggleConfigurationTests: XCTestCase {
  func testDefaultConfigurationEnablesPasswordToggle() {
    let configuration = FKTextFieldPasswordToggleConfiguration()

    XCTAssertTrue(configuration.isEnabled)
    XCTAssertNil(configuration.hiddenImage)
    XCTAssertNil(configuration.visibleImage)
    XCTAssertFalse(configuration.accessibilityLabel.isEmpty)
  }

  func testConfigurationStoresDisabledToggleState() {
    let configuration = FKTextFieldPasswordToggleConfiguration(isEnabled: false)

    XCTAssertFalse(configuration.isEnabled)
  }
}
