import FKUIKit
import XCTest

final class FKAlertConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesSingleActiveQueueAndVerticalButtons() {
    let configuration = FKAlertConfiguration()

    XCTAssertEqual(configuration.queue, .singleActive)
    XCTAssertEqual(configuration.buttonLayout, .vertical)
    XCTAssertFalse(configuration.presentation.allowsBackdropTapToDismiss)
    XCTAssertFalse(configuration.presentation.allowsSwipeToDismiss)
  }

  func testInteractionConfigurationClampsNegativeDestructiveDelay() {
    let configuration = FKAlertInteractionConfiguration(destructiveHandlerDelay: -5)

    XCTAssertEqual(configuration.destructiveHandlerDelay, 0, accuracy: 0.001)
  }

  func testTextFieldConfigurationDefaultsToCompactPreset() {
    let configuration = FKAlertTextFieldConfiguration()

    XCTAssertTrue(configuration.usesCompactPreset)
  }
}
