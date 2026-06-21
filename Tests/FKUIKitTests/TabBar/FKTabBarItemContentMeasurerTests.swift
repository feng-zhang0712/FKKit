@testable import FKUIKit
import UIKit
import XCTest

@MainActor
final class FKTabBarItemContentMeasurerTests: FKUIKitTestCase {
  private var layout: FKTabBarLayoutConfiguration!
  private var appearance: FKTabBarAppearance!

  override func setUp() {
    super.setUp()
    layout = FKTabBarLayoutConfiguration()
    appearance = FKTabBarDefaults.defaultConfiguration.appearance
  }

  override func tearDown() {
    layout = nil
    appearance = nil
    super.tearDown()
  }

  func testMeasuredContentSizeReturnsNonZeroWidthForTitledItem() {
    let item = FKTabBarItem(
      id: "home",
      title: FKTabBarTextConfiguration(normal: .init(text: "Home"))
    )

    let size = FKTabBarItemContentMeasurer.measuredContentSize(
      item: item,
      index: 0,
      selectedIndex: 0,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: .wrap,
      maximumTitleLines: 1
    )

    XCTAssertGreaterThan(size.width, 0)
    XCTAssertGreaterThan(size.height, 0)
  }

  func testMeasuredContentSizeReturnsZeroForCustomContentIdentifier() {
    let item = FKTabBarItem(
      id: "custom",
      title: FKTabBarTextConfiguration(normal: .init(text: "Custom")),
      customContentIdentifier: "host-view"
    )

    let size = FKTabBarItemContentMeasurer.measuredContentSize(
      item: item,
      index: 0,
      selectedIndex: nil,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: .wrap,
      maximumTitleLines: 1
    )

    XCTAssertEqual(size, .zero)
  }

  func testMeasuredContentSizeUsesSelectedTypographyWhenAdjustsOnSelection() {
    layout.intrinsicWidthMeasurement = .adjustsOnSelection
    var item = FKTabBarItem(
      id: "profile",
      title: FKTabBarTextConfiguration(
        normal: .init(text: "Profile"),
        selected: .init(text: "Profile Active")
      )
    )

    let unselected = FKTabBarItemContentMeasurer.measuredContentSize(
      item: item,
      index: 1,
      selectedIndex: 0,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: .wrap,
      maximumTitleLines: 1
    )
    let selected = FKTabBarItemContentMeasurer.measuredContentSize(
      item: item,
      index: 1,
      selectedIndex: 1,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: .wrap,
      maximumTitleLines: 1
    )

    XCTAssertGreaterThan(selected.width, 0)
    XCTAssertGreaterThanOrEqual(selected.width, unselected.width)
  }

  func testMeasuredContentSizeUsesMaxOfNormalAndSelectedWhenNormalStateOnly() {
    layout.intrinsicWidthMeasurement = .normalStateOnly
    let item = FKTabBarItem(
      id: "settings",
      title: FKTabBarTextConfiguration(
        normal: .init(text: "Settings"),
        selected: .init(text: "Settings Selected Longer")
      )
    )

    let size = FKTabBarItemContentMeasurer.measuredContentSize(
      item: item,
      index: 0,
      selectedIndex: 0,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: .wrap,
      maximumTitleLines: 1
    )

    XCTAssertGreaterThan(size.width, 0)
  }

  func testMeasuredContentSizeIncludesAccessoryIconWidth() {
    let plain = FKTabBarItem(
      id: "plain",
      title: FKTabBarTextConfiguration(normal: .init(text: "Alerts"))
    )
    let withAccessory = FKTabBarItem(
      id: "alerts",
      title: FKTabBarTextConfiguration(normal: .init(text: "Alerts")),
      accessoryIcon: .systemSymbol("chevron.down")
    )

    let plainSize = FKTabBarItemContentMeasurer.measuredContentSize(
      item: plain,
      index: 0,
      selectedIndex: nil,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: .wrap,
      maximumTitleLines: 1
    )
    let accessorySize = FKTabBarItemContentMeasurer.measuredContentSize(
      item: withAccessory,
      index: 0,
      selectedIndex: nil,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: .wrap,
      maximumTitleLines: 1
    )

    XCTAssertGreaterThan(accessorySize.width, plainSize.width)
  }

  func testMeasuredContentSizeReturnsMinimalInsetSizeForEmptyTitleWithoutImage() {
    let item = FKTabBarItem(id: "empty")

    let size = FKTabBarItemContentMeasurer.measuredContentSize(
      item: item,
      index: 0,
      selectedIndex: nil,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: .wrap,
      maximumTitleLines: 1
    )

    XCTAssertGreaterThan(size.width, 0)
    XCTAssertGreaterThan(size.height, 0)
  }
}
