import FKUIKit
import XCTest

final class FKRatingAccessibilityConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesLocalizedValueFormat() {
    let configuration = FKRatingAccessibilityConfiguration()

    XCTAssertNil(configuration.customLabel)
    XCTAssertNil(configuration.customHint)
    XCTAssertFalse(configuration.valueFormat.isEmpty)
  }

  func testConfigurationStoresCustomAccessibilityOverrides() {
    let configuration = FKRatingAccessibilityConfiguration(
      customLabel: "Product rating",
      customHint: "Double tap to change rating",
      valueFormat: "%@ of %@"
    )

    XCTAssertEqual(configuration.customLabel, "Product rating")
    XCTAssertEqual(configuration.customHint, "Double tap to change rating")
    XCTAssertEqual(configuration.valueFormat, "%@ of %@")
  }
}
