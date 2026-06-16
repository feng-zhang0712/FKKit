import FKUIKit
import XCTest

@MainActor
final class FKTabBarPresetsTests: XCTestCase {
  func testPagerHeaderUsesScrollableIntrinsicLayoutWithLineIndicator() {
    let configuration = FKTabBarPresets.pagerHeader(indicatorThickness: 4)

    XCTAssertTrue(configuration.layout.isScrollable)
    XCTAssertEqual(configuration.layout.widthMode, .intrinsic)
    guard case let .line(line) = configuration.appearance.indicatorStyle else {
      XCTFail("Expected line indicator")
      return
    }
    XCTAssertEqual(line.thickness, 4, accuracy: 0.001)
    XCTAssertTrue(configuration.animation.allowsProgressiveColorTransition)
  }

  func testBottomDockedUsesVerticalFillEquallyLayout() {
    let configuration = FKTabBarPresets.bottomDocked(showsIndicator: true)

    XCTAssertFalse(configuration.layout.isScrollable)
    XCTAssertEqual(configuration.layout.widthMode, .fillEqually)
    XCTAssertEqual(configuration.layout.itemLayoutDirection, .vertical)
    switch configuration.appearance.indicatorStyle {
    case .backdrop(_):
      break
    default:
      XCTFail("Expected pill indicator when showsIndicator is true")
    }
  }

  func testSegmentedControlUsesEqualWidthPillIndicator() {
    let configuration = FKTabBarPresets.segmentedControl(itemSpacing: 4)

    XCTAssertFalse(configuration.layout.isScrollable)
    XCTAssertEqual(configuration.layout.itemSpacing, 4, accuracy: 0.001)
    switch configuration.appearance.indicatorStyle {
    case .backdrop(_):
      break
    default:
      XCTFail("Expected pill indicator")
    }
  }
}
