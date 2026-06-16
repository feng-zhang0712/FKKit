import FKUIKit
import XCTest

final class FKCarouselAccessibilityConfigurationTests: XCTestCase {
  func testDefaultConfigurationEnablesScrollAndPageAnnouncements() {
    let configuration = FKCarouselAccessibilityConfiguration()

    XCTAssertTrue(configuration.supportsAccessibilityScroll)
    XCTAssertTrue(configuration.announcesPageChanges)
  }

  func testConfigurationStoresDisabledAccessibilityFlags() {
    let configuration = FKCarouselAccessibilityConfiguration(
      supportsAccessibilityScroll: false,
      announcesPageChanges: false
    )

    XCTAssertFalse(configuration.supportsAccessibilityScroll)
    XCTAssertFalse(configuration.announcesPageChanges)
  }
}
