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

  func testBottomSheetDefaultUsesBottomSheetLayout() {
    let configuration = FKSheetPresentationConfiguration.bottomSheetDefault

    guard case .bottomSheet = configuration.layout else {
      return XCTFail("Expected bottomSheet layout")
    }
    XCTAssertTrue(configuration.dismissBehavior.allowsSwipe)
  }

  func testCenterAlertUsesFixedCenterSizing() {
    let configuration = FKSheetPresentationConfiguration.centerAlert

    guard case let .center(center) = configuration.layout else {
      return XCTFail("Expected center layout")
    }
    if case let .fixed(size) = center.size {
      XCTAssertEqual(size.width, 320, accuracy: 0.001)
      XCTAssertEqual(size.height, 380, accuracy: 0.001)
    } else {
      XCTFail("Expected fixed center size")
    }
    guard case let .dim(_, alpha) = configuration.backdropStyle else {
      return XCTFail("Expected dim backdrop")
    }
    XCTAssertEqual(alpha, 0.45, accuracy: 0.001)
  }
}
