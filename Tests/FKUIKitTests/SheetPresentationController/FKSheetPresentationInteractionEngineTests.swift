@testable import FKUIKit
import XCTest

@MainActor
final class FKSheetPresentationInteractionEngineTests: XCTestCase {
  private let containerBounds = CGRect(x: 0, y: 0, width: 390, height: 844)
  private let safeInsets = UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0)

  // MARK: - sheetDismissProgress

  func testBottomSheetDismissProgressIsZeroAtRestOnSmallestDetent() {
    let heights: [CGFloat] = [280, 520]
    let environment = makeEnvironment(axis: .bottom)
    let restY = containerBounds.height - heights[0] // no safe-area policy on shell for this test
    let state = makeState(
      heights: heights,
      selectedIndex: 0,
      panStart: CGRect(x: 0, y: restY, width: 390, height: heights[0]),
      wrapper: CGRect(x: 0, y: restY, width: 390, height: heights[0])
    )

    let progress = FKSheetPresentationInteractionEngine.sheetDismissProgress(
      environment: environment,
      state: state
    )
    XCTAssertEqual(progress, 0, accuracy: 0.001)
  }

  func testBottomSheetDismissProgressIncreasesWhenPulledDown() {
    let heights: [CGFloat] = [280, 520]
    let environment = makeEnvironment(axis: .bottom)
    let restY = containerBounds.height - heights[0]
    let pulledY = restY + 120
    let state = makeState(
      heights: heights,
      selectedIndex: 0,
      panStart: CGRect(x: 0, y: restY, width: 390, height: heights[0]),
      wrapper: CGRect(x: 0, y: pulledY, width: 390, height: heights[0])
    )

    let progress = FKSheetPresentationInteractionEngine.sheetDismissProgress(
      environment: environment,
      state: state
    )
    // travel = containerHeight * 0.25 = 211; 120/211 ≈ 0.57
    XCTAssertGreaterThan(progress, 0.4)
    XCTAssertLessThanOrEqual(progress, 1)
  }

  func testTopSheetDismissProgressIncreasesWhenPulledUp() {
    let heights: [CGFloat] = [280, 520]
    let environment = makeEnvironment(axis: .top)
    let restY: CGFloat = 0
    let pulledY: CGFloat = -100
    let state = makeState(
      heights: heights,
      selectedIndex: 0,
      panStart: CGRect(x: 0, y: restY, width: 390, height: heights[0]),
      wrapper: CGRect(x: 0, y: pulledY, width: 390, height: heights[0])
    )

    let progress = FKSheetPresentationInteractionEngine.sheetDismissProgress(
      environment: environment,
      state: state
    )
    XCTAssertGreaterThan(progress, 0.3)
    XCTAssertLessThanOrEqual(progress, 1)
  }

  func testBottomSheetDismissProgressIsZeroWhenExpandedAboveSmallestDetent() {
    let heights: [CGFloat] = [280, 520]
    let environment = makeEnvironment(axis: .bottom)
    let expandedY = containerBounds.height - heights[1]
    let state = makeState(
      heights: heights,
      selectedIndex: 1,
      panStart: CGRect(x: 0, y: expandedY, width: 390, height: heights[1]),
      wrapper: CGRect(x: 0, y: expandedY, width: 390, height: heights[1])
    )

    let progress = FKSheetPresentationInteractionEngine.sheetDismissProgress(
      environment: environment,
      state: state
    )
    XCTAssertEqual(progress, 0, accuracy: 0.001)
  }

  // MARK: - centerDismissProgress

  func testCenterDismissProgressIgnoresUpwardPull() {
    let progress = FKSheetPresentationInteractionSupport.centerDismissProgress(
      translationY: -80,
      containerHeight: 844
    )
    XCTAssertEqual(progress, 0, accuracy: 0.001)
  }

  func testCenterDismissProgressScalesWithDownwardPull() {
    let progress = FKSheetPresentationInteractionSupport.centerDismissProgress(
      translationY: 200,
      containerHeight: 800
    )
    // travel = 800 * 0.4 = 320; 200/320 = 0.625
    XCTAssertEqual(progress, 0.625, accuracy: 0.001)
  }

  // MARK: - Helpers

  private func makeEnvironment(axis: FKSheetPresentationAxis) -> FKSheetPresentationInteractionEnvironment {
    let layout: FKSheetPresentationConfiguration.Layout = {
      switch axis {
      case .bottom: return .bottomSheet(.init())
      case .top: return .topSheet(.init())
      }
    }()
    var configuration = FKSheetPresentationConfiguration()
    configuration.layout = layout
    // Use ignore-safe-area shell so rest Y math matches simple height subtraction in tests.
    configuration.safeAreaPolicy = .contentRespectsSafeArea

    return FKSheetPresentationInteractionEnvironment(
      axis: axis,
      sheet: configuration.sheet,
      dismissBehaviorAllowsSwipe: true,
      safeAreaPolicy: configuration.safeAreaPolicy,
      containerBounds: containerBounds,
      containerSafeInsets: .zero
    )
  }

  private func makeState(
    heights: [CGFloat],
    selectedIndex: Int,
    panStart: CGRect,
    wrapper: CGRect
  ) -> FKSheetPresentationInteractionState {
    FKSheetPresentationInteractionState(
      resolvedDetentHeights: heights,
      selectedDetentIndex: selectedIndex,
      sheetPanBeganDetentIndex: selectedIndex,
      panStartFrame: panStart,
      wrapperFrame: wrapper
    )
  }
}
