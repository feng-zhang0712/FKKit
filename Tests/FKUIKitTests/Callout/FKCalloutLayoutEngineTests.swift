@testable import FKUIKit
import XCTest

@MainActor
final class FKCalloutLayoutEngineTests: FKUIKitTestCase {
  func testBottomPlacementPositionsBubbleBelowAnchor() {
    let container = CGRect(x: 0, y: 0, width: 390, height: 844)
    let anchor = CGRect(x: 145, y: 400, width: 100, height: 44)
    let bubbleSize = CGSize(width: 220, height: 80)

    let result = FKCalloutLayoutEngine.layout(
      anchorRectInWindow: anchor,
      bubbleSize: bubbleSize,
      placement: .bottom,
      anchorSpacing: 8,
      anchorAlignment: .center,
      beakOffset: .automatic,
      beakWidth: 16,
      cornerRadius: 12,
      beakCornerInset: 8,
      layoutDirection: .leftToRight,
      safeAreaInsets: .zero,
      containerBounds: container,
      screenEdgeMargin: 16,
      flipsWhenNeeded: false
    )

    XCTAssertEqual(result.placement, .bottom)
    XCTAssertGreaterThanOrEqual(result.frame.minY, anchor.maxY + 8 - 0.5)
    XCTAssertEqual(result.frame.width, bubbleSize.width, accuracy: 0.5)
    XCTAssertTrue(container.insetBy(dx: 16, dy: 16).contains(result.frame))
  }

  func testAutomaticPlacementChoosesSideWithMoreAvailableSpace() {
    let container = CGRect(x: 0, y: 0, width: 390, height: 844)
    let anchorNearTop = CGRect(x: 145, y: 40, width: 100, height: 44)
    let bubbleSize = CGSize(width: 200, height: 72)

    let result = FKCalloutLayoutEngine.layout(
      anchorRectInWindow: anchorNearTop,
      bubbleSize: bubbleSize,
      placement: .automatic,
      anchorSpacing: 8,
      anchorAlignment: .center,
      beakOffset: .automatic,
      beakWidth: 16,
      cornerRadius: 12,
      beakCornerInset: 8,
      layoutDirection: .leftToRight,
      safeAreaInsets: UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0),
      containerBounds: container,
      screenEdgeMargin: 16,
      flipsWhenNeeded: true
    )

    XCTAssertEqual(result.placement, .bottom)
    XCTAssertGreaterThan(result.frame.minY, anchorNearTop.maxY)
  }
}
