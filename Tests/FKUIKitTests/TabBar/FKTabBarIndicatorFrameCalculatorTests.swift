@testable import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKTabBarIndicatorFrameCalculatorTests: FKUIKitTestCase {
  private let itemFrame = CGRect(x: 20, y: 0, width: 80, height: 48)
  private let contentFrame = CGRect(x: 32, y: 8, width: 56, height: 32)
  private let containerBounds = CGRect(x: 0, y: 0, width: 320, height: 48)

  func testNoneStyleReturnsZeroFrame() {
    let frame = FKTabBarIndicatorFrameCalculator.frame(
      style: .none,
      itemFrame: itemFrame,
      contentFrame: contentFrame,
      containerBounds: containerBounds,
      customResolver: nil
    )

    XCTAssertEqual(frame, .zero)
  }

  func testLineStylePlacesIndicatorAtBottomOfItemFrame() {
    var config = FKTabBarLineIndicatorConfiguration()
    config.thickness = 4
    config.leadingInset = 0
    config.trailingInset = 0

    let frame = FKTabBarIndicatorFrameCalculator.frame(
      style: .line(config),
      itemFrame: itemFrame,
      contentFrame: contentFrame,
      containerBounds: containerBounds,
      customResolver: nil
    )

    XCTAssertEqual(frame.maxY, itemFrame.maxY, accuracy: 0.001)
    XCTAssertEqual(frame.height, 4, accuracy: 0.001)
    XCTAssertEqual(frame.width, itemFrame.width, accuracy: 0.001)
  }

  func testLineStyleCentersFixedWidthWithinAvailableSpan() {
    var config = FKTabBarLineIndicatorConfiguration()
    config.fixedWidth = 20
    config.leadingInset = 10
    config.trailingInset = 10
    config.thickness = 3

    let frame = FKTabBarIndicatorFrameCalculator.frame(
      style: .line(config),
      itemFrame: itemFrame,
      contentFrame: contentFrame,
      containerBounds: containerBounds,
      customResolver: nil
    )

    XCTAssertEqual(frame.width, 20, accuracy: 0.001)
    XCTAssertEqual(frame.midX, itemFrame.midX, accuracy: 0.001)
  }

  func testLineStyleSupportsTopPosition() {
    var config = FKTabBarLineIndicatorConfiguration()
    config.position = .top
    config.thickness = 2

    let frame = FKTabBarIndicatorFrameCalculator.frame(
      style: .line(config),
      itemFrame: itemFrame,
      contentFrame: contentFrame,
      containerBounds: containerBounds,
      customResolver: nil
    )

    XCTAssertEqual(frame.minY, itemFrame.minY, accuracy: 0.001)
  }

  func testBackdropStyleInsetsItemFrame() {
    var config = FKTabBarBackgroundIndicatorConfiguration()
    config.insets = .init(top: 4, leading: 6, bottom: 4, trailing: 6)

    let frame = FKTabBarIndicatorFrameCalculator.frame(
      style: .backdrop(config),
      itemFrame: itemFrame,
      contentFrame: contentFrame,
      containerBounds: containerBounds,
      customResolver: nil
    )

    XCTAssertEqual(frame, itemFrame.inset(by: UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)))
  }

  func testCustomResolverOverridesComputedFrame() {
    let custom = CGRect(x: 5, y: 5, width: 10, height: 10)

    let frame = FKTabBarIndicatorFrameCalculator.frame(
      style: .line(FKTabBarLineIndicatorConfiguration()),
      itemFrame: itemFrame,
      contentFrame: contentFrame,
      containerBounds: containerBounds,
      customResolver: { _, _ in custom }
    )

    XCTAssertEqual(frame, custom)
  }

  func testTrackContentFrameUsesContentBoundsForLineIndicator() {
    var config = FKTabBarLineIndicatorConfiguration()
    config.followMode = .trackContentFrame
    config.leadingInset = 0
    config.trailingInset = 0

    let frame = FKTabBarIndicatorFrameCalculator.frame(
      style: .line(config),
      itemFrame: itemFrame,
      contentFrame: contentFrame,
      containerBounds: containerBounds,
      customResolver: nil
    )

    XCTAssertEqual(frame.width, contentFrame.width, accuracy: 0.001)
    XCTAssertEqual(frame.minX, contentFrame.minX, accuracy: 0.001)
  }

  func testLineStyleSupportsCenterPosition() {
    var config = FKTabBarLineIndicatorConfiguration()
    config.position = .center
    config.thickness = 6

    let frame = FKTabBarIndicatorFrameCalculator.frame(
      style: .line(config),
      itemFrame: itemFrame,
      contentFrame: contentFrame,
      containerBounds: containerBounds,
      customResolver: nil
    )

    XCTAssertEqual(frame.midY, itemFrame.midY, accuracy: 0.001)
    XCTAssertEqual(frame.height, 6, accuracy: 0.001)
  }
}
