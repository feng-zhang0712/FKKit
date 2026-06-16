import FKUIKit
import XCTest

final class FKRatingLayoutConfigurationTests: XCTestCase {
  func testInitClampsItemCountAndItemSizeToMinimumValues() {
    let configuration = FKRatingLayoutConfiguration(
      itemCount: 0,
      itemSize: CGSize(width: 1, height: 2),
      itemSpacing: -4,
      labelSpacing: -2
    )

    XCTAssertEqual(configuration.itemCount, 1)
    XCTAssertEqual(configuration.itemSize.width, 4, accuracy: 0.001)
    XCTAssertEqual(configuration.itemSize.height, 4, accuracy: 0.001)
    XCTAssertEqual(configuration.itemSpacing, 0, accuracy: 0.001)
    XCTAssertEqual(configuration.labelSpacing, 0, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesFiveItemsAndNoLabelPlacement() {
    let configuration = FKRatingLayoutConfiguration()

    XCTAssertEqual(configuration.itemCount, 5)
    XCTAssertEqual(configuration.labelPlacement, .none)
  }
}
