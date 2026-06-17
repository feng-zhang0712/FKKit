import FKUIKit
import XCTest

@MainActor
final class FKSheetPreferredContentSizingTests: FKUIKitTestCase {
  func testResolvedShellHeightAddsGrabberAndBottomSafeAreaForContentOnlyBottomSheet() {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.preferredContentSizeReporting = .contentOnly
    configuration.safeAreaPolicy = .contentRespectsSafeArea
    configuration.sheet.prefersGrabberVisible = true

    let shellHeight = configuration.resolvedShellHeight(
      fromContentHeight: 200,
      layout: configuration.layout,
      containerSafeAreaInsets: UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 0)
    )

    let grabberTop = configuration.grabberReservedInsets(for: configuration.layout).top
    XCTAssertEqual(shellHeight, 200 + grabberTop + 34, accuracy: 0.001)
  }

  func testResolvedShellHeightReturnsContentHeightForShellHeightReporting() {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.preferredContentSizeReporting = .shellHeight

    let shellHeight = configuration.resolvedShellHeight(
      fromContentHeight: 240,
      layout: configuration.layout,
      containerSafeAreaInsets: UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 0)
    )

    XCTAssertEqual(shellHeight, 240, accuracy: 0.001)
  }

  func testResolvedShellHeightIgnoresSafeAreaForCenterLayout() {
    var configuration = FKSheetPresentationConfiguration.centerCard
    configuration.preferredContentSizeReporting = .contentOnly

    let shellHeight = configuration.resolvedShellHeight(
      fromContentHeight: 180,
      layout: configuration.layout,
      containerSafeAreaInsets: UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
    )

    XCTAssertEqual(shellHeight, 180, accuracy: 0.001)
  }
}
