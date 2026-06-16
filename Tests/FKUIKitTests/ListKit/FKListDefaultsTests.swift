import FKUIKit
import XCTest

final class FKListDefaultsTests: XCTestCase {
  func testFeedConfigurationEnablesPrefetchAndDisablesLoadMoreAnimation() {
    let feed = FKListDefaults.feedConfiguration

    XCTAssertTrue(feed.prefetch.isEnabled)
    XCTAssertEqual(feed.animation.defaultRowAnimation, .none)
    XCTAssertFalse(feed.animation.animatesLoadMoreDifferences)
    XCTAssertFalse(feed.animation.animatesRefreshDifferences)
    XCTAssertEqual(feed.layout.estimatedRowHeight, 72)
  }

  func testSettingsConfigurationUsesFadeAnimationAndDisablesPrefetch() {
    let settings = FKListDefaults.settingsConfiguration

    XCTAssertFalse(settings.prefetch.isEnabled)
    XCTAssertEqual(settings.animation.defaultRowAnimation, .fade)
    XCTAssertFalse(settings.animation.animatesLoadMoreDifferences)
  }

  func testDefaultConfigurationMatchesFreshListConfiguration() {
    XCTAssertEqual(FKListDefaults.defaultConfiguration, FKListConfiguration())
  }
}
