@testable import FKUIKit
import XCTest

final class FKAvatarGroupLayoutEngineTests: XCTestCase {
  func testLayoutWithZeroAvatarsAndOverflowUsesOverflowWidthOnly() {
    let metrics = FKAvatarGroupLayoutEngine.layout(
      visibleAvatarCount: 0,
      showsOverflow: true,
      avatarDiameter: 40,
      overlap: -8,
      overflowDiameter: 32,
      direction: .leadingToTrailing,
      isRTL: false
    )

    XCTAssertTrue(metrics.avatarFrames.isEmpty)
    XCTAssertNotNil(metrics.overflowFrame)
    XCTAssertEqual(metrics.overflowFrame!.width, 32, accuracy: 0.001)
    XCTAssertEqual(metrics.totalSize.width, 32, accuracy: 0.001)
  }

  func testLayoutComputesOverlappedAvatarPositions() {
    let metrics = FKAvatarGroupLayoutEngine.layout(
      visibleAvatarCount: 3,
      showsOverflow: false,
      avatarDiameter: 40,
      overlap: -8,
      overflowDiameter: 32,
      direction: .leadingToTrailing,
      isRTL: false
    )

    XCTAssertEqual(metrics.avatarFrames.count, 3)
    XCTAssertEqual(metrics.avatarFrames[0].origin.x, 0, accuracy: 0.001)
    XCTAssertEqual(metrics.avatarFrames[1].origin.x, 32, accuracy: 0.001)
    XCTAssertEqual(metrics.avatarFrames[2].origin.x, 64, accuracy: 0.001)
    XCTAssertEqual(metrics.totalSize.width, 104, accuracy: 0.001)
  }

  func testLayoutPlacesOverflowAfterLastAvatarWhenLeadingToTrailing() {
    let metrics = FKAvatarGroupLayoutEngine.layout(
      visibleAvatarCount: 2,
      showsOverflow: true,
      avatarDiameter: 40,
      overlap: -8,
      overflowDiameter: 32,
      direction: .leadingToTrailing,
      isRTL: false
    )

    XCTAssertNotNil(metrics.overflowFrame)
    XCTAssertEqual(metrics.overflowFrame!.origin.x, 64, accuracy: 0.001)
    XCTAssertEqual(metrics.totalSize.width, 96, accuracy: 0.001)
  }

  func testLayoutTrailingToLeadingStacksFromTrailingEdge() {
    let metrics = FKAvatarGroupLayoutEngine.layout(
      visibleAvatarCount: 2,
      showsOverflow: false,
      avatarDiameter: 40,
      overlap: -8,
      overflowDiameter: 32,
      direction: .trailingToLeading,
      isRTL: false
    )

    XCTAssertEqual(metrics.avatarFrames[0].maxX, metrics.totalSize.width, accuracy: 0.001)
    XCTAssertGreaterThan(metrics.avatarFrames[0].origin.x, metrics.avatarFrames[1].origin.x)
  }

  func testLayoutLeadingToTrailingReversesOrderWhenRTL() {
    let ltr = FKAvatarGroupLayoutEngine.layout(
      visibleAvatarCount: 2,
      showsOverflow: false,
      avatarDiameter: 40,
      overlap: -8,
      overflowDiameter: 32,
      direction: .leadingToTrailing,
      isRTL: false
    )
    let rtl = FKAvatarGroupLayoutEngine.layout(
      visibleAvatarCount: 2,
      showsOverflow: false,
      avatarDiameter: 40,
      overlap: -8,
      overflowDiameter: 32,
      direction: .leadingToTrailing,
      isRTL: true
    )

    XCTAssertEqual(ltr.avatarFrames.map(\.origin.x), [0, 32])
    XCTAssertEqual(rtl.avatarFrames.map(\.origin.x), [32, 0])
  }

  func testLayoutOverflowAnchorsAtLeadingEdgeWhenTrailingToLeading() {
    let metrics = FKAvatarGroupLayoutEngine.layout(
      visibleAvatarCount: 2,
      showsOverflow: true,
      avatarDiameter: 40,
      overlap: -8,
      overflowDiameter: 32,
      direction: .trailingToLeading,
      isRTL: false
    )

    XCTAssertNotNil(metrics.overflowFrame)
    XCTAssertEqual(metrics.overflowFrame!.origin.x, 0, accuracy: 0.001)
  }

  func testLayoutUsesAvatarDiameterForTotalHeight() {
    let metrics = FKAvatarGroupLayoutEngine.layout(
      visibleAvatarCount: 1,
      showsOverflow: false,
      avatarDiameter: 48,
      overlap: 0,
      overflowDiameter: 32,
      direction: .leadingToTrailing,
      isRTL: false
    )

    XCTAssertEqual(metrics.totalSize.height, 48, accuracy: 0.001)
    XCTAssertEqual(metrics.avatarFrames[0].height, 48, accuracy: 0.001)
  }

  func testLayoutClampsNegativeVisibleCountToZero() {
    let metrics = FKAvatarGroupLayoutEngine.layout(
      visibleAvatarCount: -2,
      showsOverflow: false,
      avatarDiameter: 40,
      overlap: 0,
      overflowDiameter: 32,
      direction: .leadingToTrailing,
      isRTL: false
    )

    XCTAssertTrue(metrics.avatarFrames.isEmpty)
    XCTAssertEqual(metrics.totalSize.width, 0, accuracy: 0.001)
  }
}
