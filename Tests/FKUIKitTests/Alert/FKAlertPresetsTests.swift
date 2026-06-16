import FKUIKit
import XCTest

final class FKAlertPresetsTests: XCTestCase {
  func testDestructiveConfirmDisablesBackdropAndSwipeDismiss() {
    let configuration = FKAlertPresets.destructiveConfirm()

    XCTAssertFalse(configuration.presentation.allowsBackdropTapToDismiss)
    XCTAssertFalse(configuration.presentation.allowsSwipeToDismiss)
    XCTAssertTrue(configuration.interaction.hapticOnDestructive)
  }

  func testInformationalEnablesBackdropTapDismiss() {
    let configuration = FKAlertPresets.informational()

    XCTAssertTrue(configuration.presentation.allowsBackdropTapToDismiss)
    XCTAssertFalse(configuration.presentation.allowsSwipeToDismiss)
    XCTAssertEqual(configuration.queue, .singleActive)
  }

  func testTextPromptAutoFocusesTextField() {
    let configuration = FKAlertPresets.textPrompt()

    XCTAssertTrue(configuration.interaction.autoFocusTextField)
    XCTAssertTrue(configuration.presentation.allowsBackdropTapToDismiss)
  }

  func testInteractionConfigurationClampsDestructiveHandlerDelayToZeroOrMore() {
    let configuration = FKAlertInteractionConfiguration(destructiveHandlerDelay: -5)
    XCTAssertEqual(configuration.destructiveHandlerDelay, 0, accuracy: 0.001)
  }
}
