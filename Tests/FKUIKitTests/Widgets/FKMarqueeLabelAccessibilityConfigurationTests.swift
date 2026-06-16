import FKUIKit
import XCTest

final class FKMarqueeLabelAccessibilityConfigurationTests: XCTestCase {
  func testDefaultConfigurationDoesNotUseUpdatesFrequentlyTrait() {
    let configuration = FKMarqueeLabelAccessibilityConfiguration()

    XCTAssertNil(configuration.customLabel)
    XCTAssertFalse(configuration.usesUpdatesFrequentlyTraitWhenScrolling)
  }

  func testConfigurationStoresCustomLabelAndTraitFlag() {
    let configuration = FKMarqueeLabelAccessibilityConfiguration(
      customLabel: "Breaking news ticker",
      usesUpdatesFrequentlyTraitWhenScrolling: true
    )

    XCTAssertEqual(configuration.customLabel, "Breaking news ticker")
    XCTAssertTrue(configuration.usesUpdatesFrequentlyTraitWhenScrolling)
  }
}
