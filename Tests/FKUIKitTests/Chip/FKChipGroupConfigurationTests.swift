import FKUIKit
import XCTest

final class FKChipGroupConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesFlowLayoutAndFilterMode() {
    let configuration = FKChipGroupConfiguration()

    if case .flow = configuration.layoutMode {
      XCTAssertEqual(configuration.itemSpacing, 8, accuracy: 0.001)
    } else {
      XCTFail("Expected flow layout mode")
    }
    XCTAssertEqual(configuration.chipMode, .filter)
    XCTAssertTrue(configuration.scrollsToSelectedChip)
    XCTAssertEqual(configuration.horizontalScrollTrailingPeek, 24, accuracy: 0.001)
  }

  func testConfigurationStoresCustomSpacingAndOverflowBehavior() {
    let configuration = FKChipGroupConfiguration(
      itemSpacing: 12,
      lineSpacing: 10,
      chipMode: .choice,
      overflowBehavior: .notify,
      scrollsToSelectedChip: false,
      horizontalScrollTrailingPeek: 16
    )

    XCTAssertEqual(configuration.itemSpacing, 12, accuracy: 0.001)
    XCTAssertEqual(configuration.lineSpacing, 10, accuracy: 0.001)
    XCTAssertEqual(configuration.chipMode, .choice)
    XCTAssertEqual(configuration.overflowBehavior, .notify)
    XCTAssertFalse(configuration.scrollsToSelectedChip)
    XCTAssertEqual(configuration.horizontalScrollTrailingPeek, 16, accuracy: 0.001)
  }
}
