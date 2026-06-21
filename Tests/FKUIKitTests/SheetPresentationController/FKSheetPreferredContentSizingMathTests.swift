@testable import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKSheetPreferredContentSizingMathTests: FKUIKitTestCase {
  func testShellHeightReturnsContentHeightForShellHeightReporting() {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.preferredContentSizeReporting = .shellHeight

    let shell = FKSheetPreferredContentSizingMath.shellHeight(
      fromContentHeight: 220,
      configuration: configuration,
      layout: configuration.layout,
      containerSafeAreaInsets: UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 0)
    )

    XCTAssertEqual(shell, 220, accuracy: 0.001)
  }

  func testShellHeightAddsGrabberAndBottomSafeAreaForContentOnlyBottomSheet() {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.preferredContentSizeReporting = .contentOnly
    configuration.safeAreaPolicy = .contentRespectsSafeArea
    configuration.sheet.prefersGrabberVisible = true

    let shell = FKSheetPreferredContentSizingMath.shellHeight(
      fromContentHeight: 200,
      configuration: configuration,
      layout: configuration.layout,
      containerSafeAreaInsets: UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 0)
    )

    let grabberTop = configuration.grabberReservedInsets(for: configuration.layout).top
    XCTAssertEqual(shell, 200 + grabberTop + 34, accuracy: 0.001)
  }

  func testHostedContentHeightInvertsContentOnlyBottomSheetConversion() {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.preferredContentSizeReporting = .contentOnly
    configuration.safeAreaPolicy = .contentRespectsSafeArea
    configuration.sheet.prefersGrabberVisible = true
    let safeArea = UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 0)

    let shell = FKSheetPreferredContentSizingMath.shellHeight(
      fromContentHeight: 180,
      configuration: configuration,
      layout: configuration.layout,
      containerSafeAreaInsets: safeArea
    )
    let hosted = FKSheetPreferredContentSizingMath.hostedContentHeight(
      fromShellHeight: shell,
      configuration: configuration,
      layout: configuration.layout,
      containerSafeAreaInsets: safeArea
    )

    XCTAssertEqual(hosted, 180, accuracy: 0.001)
  }

  func testShellHeightIgnoresSafeAreaForCenterLayout() {
    var configuration = FKSheetPresentationConfiguration.centerCard
    configuration.preferredContentSizeReporting = .contentOnly

    let shell = FKSheetPreferredContentSizingMath.shellHeight(
      fromContentHeight: 160,
      configuration: configuration,
      layout: configuration.layout,
      containerSafeAreaInsets: UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
    )

    XCTAssertEqual(shell, 160, accuracy: 0.001)
  }

  func testHostedContentHeightClampsToMinimumFortyFourPoints() {
    var configuration = FKSheetPresentationConfiguration.bottomSheetDefault
    configuration.preferredContentSizeReporting = .contentOnly
    configuration.sheet.prefersGrabberVisible = false

    let hosted = FKSheetPreferredContentSizingMath.hostedContentHeight(
      fromShellHeight: 10,
      configuration: configuration,
      layout: configuration.layout,
      containerSafeAreaInsets: .zero
    )

    XCTAssertEqual(hosted, 44, accuracy: 0.001)
  }

  func testTopSheetContentOnlyAddsGrabberBottomAndTopSafeArea() {
    var configuration = FKSheetPresentationConfiguration.topSheetDefault
    configuration.preferredContentSizeReporting = .contentOnly
    configuration.safeAreaPolicy = .contentRespectsSafeArea
    configuration.sheet.prefersGrabberVisible = true
    let safeArea = UIEdgeInsets(top: 47, left: 0, bottom: 0, right: 0)

    let shell = FKSheetPreferredContentSizingMath.shellHeight(
      fromContentHeight: 240,
      configuration: configuration,
      layout: configuration.layout,
      containerSafeAreaInsets: safeArea
    )
    let grabberBottom = configuration.grabberReservedInsets(for: configuration.layout).bottom

    XCTAssertEqual(shell, 240 + grabberBottom + 47, accuracy: 0.001)
  }
}
