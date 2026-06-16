import FKUIKit
import XCTest

final class FKTagConfigurationTests: XCTestCase {
  func testLayoutDefaultsToSmallChipSize() {
    let layout = FKTagLayoutConfiguration()
    XCTAssertEqual(layout.size, .s)
    XCTAssertEqual(layout.horizontalPadding, 10, accuracy: 0.001)
  }

  func testConfigurationEqualityComparesLayoutAndAccessibility() {
    let first = FKTagConfiguration(
      layout: FKTagLayoutConfiguration(size: .m),
      accessibility: FKTagAccessibilityConfiguration(customLabel: "Tag")
    )
    let matching = FKTagConfiguration(
      layout: FKTagLayoutConfiguration(size: .m),
      accessibility: FKTagAccessibilityConfiguration(customLabel: "Tag")
    )
    let different = FKTagConfiguration(
      accessibility: FKTagAccessibilityConfiguration(customLabel: "Other")
    )

    XCTAssertEqual(first, matching)
    XCTAssertNotEqual(first, different)
  }
}
