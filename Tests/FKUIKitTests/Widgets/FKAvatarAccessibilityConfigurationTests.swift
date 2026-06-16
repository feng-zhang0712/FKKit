import FKUIKit
import XCTest

final class FKAvatarAccessibilityConfigurationTests: XCTestCase {
  func testDefaultConfigurationAnnouncesLoadingStateChanges() {
    let configuration = FKAvatarAccessibilityConfiguration()

    XCTAssertNil(configuration.customLabel)
    XCTAssertNil(configuration.hint)
    XCTAssertTrue(configuration.announcesLoadingStateChanges)
  }

  func testConfigurationStoresCustomLabelAndHint() {
    let configuration = FKAvatarAccessibilityConfiguration(
      customLabel: "Profile photo",
      hint: "Opens profile",
      announcesLoadingStateChanges: false
    )

    XCTAssertEqual(configuration.customLabel, "Profile photo")
    XCTAssertEqual(configuration.hint, "Opens profile")
    XCTAssertFalse(configuration.announcesLoadingStateChanges)
  }
}
