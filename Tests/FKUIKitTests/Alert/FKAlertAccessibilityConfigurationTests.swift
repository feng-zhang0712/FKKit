import FKUIKit
import XCTest

final class FKAlertAccessibilityConfigurationTests: XCTestCase {
  func testDefaultConfigurationAnnouncesOnPresent() {
    let configuration = FKAlertAccessibilityConfiguration()

    XCTAssertTrue(configuration.announcesOnPresent)
    XCTAssertFalse(configuration.destructiveHint?.isEmpty ?? true)
  }

  func testConfigurationStoresCustomAnnouncementAndDestructiveHint() {
    let configuration = FKAlertAccessibilityConfiguration(
      announcesOnPresent: false,
      destructiveHint: "This action cannot be undone"
    )

    XCTAssertFalse(configuration.announcesOnPresent)
    XCTAssertEqual(configuration.destructiveHint, "This action cannot be undone")
  }
}
