import FKUIKit
import XCTest

final class FKTextFieldClearButtonConfigurationTests: XCTestCase {
  func testDefaultConfigurationEnablesClearButtonWithoutResigning() {
    let configuration = FKTextFieldClearButtonConfiguration()

    XCTAssertTrue(configuration.isEnabled)
    XCTAssertFalse(configuration.resignsFirstResponderOnTap)
    XCTAssertFalse(configuration.accessibilityLabel.isEmpty)
  }

  func testConfigurationStoresCustomResignBehavior() {
    let configuration = FKTextFieldClearButtonConfiguration(
      isEnabled: false,
      resignsFirstResponderOnTap: true
    )

    XCTAssertFalse(configuration.isEnabled)
    XCTAssertTrue(configuration.resignsFirstResponderOnTap)
  }
}
