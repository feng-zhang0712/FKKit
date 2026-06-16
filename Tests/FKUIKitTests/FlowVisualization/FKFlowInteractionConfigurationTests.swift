import FKUIKit
import XCTest

final class FKFlowInteractionConfigurationTests: XCTestCase {
  func testInitClampsTouchTargetAndDisabledAlpha() {
    let configuration = FKFlowInteractionConfiguration(
      minimumTouchTargetSize: CGSize(width: 8, height: 8),
      disabledAlpha: 0
    )

    XCTAssertEqual(configuration.minimumTouchTargetSize.width, 24, accuracy: 0.001)
    XCTAssertEqual(configuration.minimumTouchTargetSize.height, 24, accuracy: 0.001)
    XCTAssertEqual(configuration.disabledAlpha, 0.1, accuracy: 0.001)
  }

  func testDefaultConfigurationDisablesSelection() {
    let configuration = FKFlowInteractionConfiguration()

    XCTAssertFalse(configuration.allowsSelection)
    XCTAssertEqual(configuration.selectableStates, [.completed])
    XCTAssertFalse(configuration.hapticOnSelect)
  }
}
