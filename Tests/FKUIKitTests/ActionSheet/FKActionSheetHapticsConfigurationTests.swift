import FKUIKit
import XCTest

final class FKActionSheetHapticsConfigurationTests: XCTestCase {
  func testDefaultConfigurationDisablesSelectionHaptics() {
    let configuration = FKActionSheetHapticsConfiguration()

    XCTAssertFalse(configuration.onActionSelection)
    XCTAssertEqual(configuration.impactStyle, .light)
  }

  func testConfigurationStoresEnabledSelectionAndImpactStyle() {
    let configuration = FKActionSheetHapticsConfiguration(
      onActionSelection: true,
      impactStyle: .medium
    )

    XCTAssertTrue(configuration.onActionSelection)
    XCTAssertEqual(configuration.impactStyle, .medium)
  }
}
