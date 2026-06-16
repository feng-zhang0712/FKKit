import FKUIKit
import XCTest

final class FKProgressBarAccessibilityConfigurationTests: XCTestCase {
  func testDefaultConfigurationTreatsProgressAsFrequentUpdates() {
    let configuration = FKProgressBarAccessibilityConfiguration()

    XCTAssertNil(configuration.customLabel)
    XCTAssertNil(configuration.customHint)
    XCTAssertTrue(configuration.treatAsFrequentUpdates)
  }

  func testConfigurationStoresCustomLabelHintAndUpdateTrait() {
    let configuration = FKProgressBarAccessibilityConfiguration(
      customLabel: "Upload progress",
      customHint: "Shows remaining upload time",
      treatAsFrequentUpdates: false
    )

    XCTAssertEqual(configuration.customLabel, "Upload progress")
    XCTAssertEqual(configuration.customHint, "Shows remaining upload time")
    XCTAssertFalse(configuration.treatAsFrequentUpdates)
  }
}
