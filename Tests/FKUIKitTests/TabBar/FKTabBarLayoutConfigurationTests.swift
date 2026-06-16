import FKUIKit
import XCTest

@MainActor
final class FKTabBarLayoutConfigurationTests: XCTestCase {
  func testDefaultLayoutUsesScrollableStandaloneStrip() {
    let layout = FKTabBarLayoutConfiguration()

    XCTAssertTrue(layout.isScrollable)
    XCTAssertEqual(layout.hostingContext, .standalone)
    XCTAssertEqual(layout.minimumItemHeight, 44, accuracy: 0.001)
    XCTAssertEqual(layout.widthMode, .intrinsic)
  }

  func testConfigurationStoresCustomSpacingAndOverflowPolicy() {
    let layout = FKTabBarLayoutConfiguration(
      isScrollable: false,
      hostingContext: .navigationBarTitleView,
      itemSpacing: 12,
      nonScrollableOverflowPolicy: .truncate,
      emptyStateMessage: "No tabs"
    )

    XCTAssertFalse(layout.isScrollable)
    XCTAssertEqual(layout.hostingContext, .navigationBarTitleView)
    XCTAssertEqual(layout.itemSpacing, 12, accuracy: 0.001)
    XCTAssertEqual(layout.nonScrollableOverflowPolicy, .truncate)
    XCTAssertEqual(layout.emptyStateMessage, "No tabs")
  }
}
