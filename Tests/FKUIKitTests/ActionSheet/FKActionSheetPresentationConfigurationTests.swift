import FKUIKit
import XCTest

final class FKActionSheetPresentationConfigurationTests: XCTestCase {
  func testInitClampsBackdropAlphaAndFitContentFraction() {
    let configuration = FKActionSheetPresentationConfiguration(
      backdropAlpha: -0.5,
      maximumFitContentHeightFraction: 0.05
    )

    XCTAssertEqual(configuration.backdropAlpha, 0, accuracy: 0.001)
    XCTAssertEqual(configuration.maximumFitContentHeightFraction, 0.2, accuracy: 0.001)
  }

  func testInitClampsPanelWidthAndHorizontalInset() {
    let configuration = FKActionSheetPresentationConfiguration(
      maxPanelWidth: 100,
      horizontalInset: -8
    )

    XCTAssertEqual(configuration.maxPanelWidth, 200, accuracy: 0.001)
    XCTAssertEqual(configuration.horizontalInset, 0, accuracy: 0.001)
  }

  func testCenteredPresetUsesCenteredStyleWithCardInsets() {
    let configuration = FKActionSheetPresentationConfiguration.centered

    XCTAssertEqual(configuration.style, .centered)
    XCTAssertEqual(configuration.cornerRadius, 12, accuracy: 0.001)
    XCTAssertEqual(configuration.horizontalInset, 12, accuracy: 0.001)
  }

  func testPopoverPresetDisablesBackdropDismiss() {
    let configuration = FKActionSheetPresentationConfiguration.popover

    XCTAssertEqual(configuration.style, .popover)
    XCTAssertFalse(configuration.allowsTapOutsideDismiss)
    XCTAssertEqual(configuration.backdropAlpha, 0, accuracy: 0.001)
  }
}
