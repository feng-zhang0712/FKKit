import FKUIKit
import XCTest

@MainActor
final class FKSheetPresentationPresetsTests: XCTestCase {
  func testTopSheetDefaultUsesTopLayoutWithMediumInitialDetent() {
    let configuration = FKSheetPresentationConfiguration.topSheetDefault

    guard case let .topSheet(sheet) = configuration.layout else {
      XCTFail("Expected topSheet layout")
      return
    }
    XCTAssertEqual(sheet.initialSelectedDetentIndex, 1)
    XCTAssertTrue(sheet.detents.contains(.medium))
  }

  func testCenterCardUsesDimBackdropAndRoundedCorners() {
    let configuration = FKSheetPresentationConfiguration.centerCard

    guard case .center = configuration.layout else {
      XCTFail("Expected center layout")
      return
    }
    XCTAssertEqual(configuration.cornerRadius, 14, accuracy: 0.001)
    guard case let .dim(_, alpha) = configuration.backdropStyle else {
      XCTFail("Expected dim backdrop")
      return
    }
    XCTAssertEqual(alpha, 0.4, accuracy: 0.001)
  }

  func testPassthroughOverlayEnablesBackgroundInteraction() {
    let configuration = FKSheetPresentationConfiguration.passthroughOverlay

    XCTAssertTrue(configuration.backgroundInteraction.isEnabled)
    XCTAssertEqual(configuration.sheet.detents, [.fitContent, .medium])
  }
}
