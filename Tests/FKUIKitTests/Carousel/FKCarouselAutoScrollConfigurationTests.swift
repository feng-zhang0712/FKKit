import FKUIKit
import XCTest

final class FKCarouselAutoScrollConfigurationTests: XCTestCase {
  func testDefaultConfigurationIsDisabledWithForwardDirection() {
    let configuration = FKCarouselAutoScrollConfiguration()

    XCTAssertFalse(configuration.isEnabled)
    XCTAssertEqual(configuration.interval, 3, accuracy: 0.001)
    XCTAssertEqual(configuration.direction, .forward)
    XCTAssertTrue(configuration.pausesOnUserInteraction)
  }

  func testConfigurationStoresCustomIntervalAndPauseFlags() {
    let configuration = FKCarouselAutoScrollConfiguration(
      isEnabled: true,
      interval: 5,
      repeats: false,
      direction: .reverse,
      pausesOnUserInteraction: false,
      pausesWhenOffscreen: false
    )

    XCTAssertTrue(configuration.isEnabled)
    XCTAssertEqual(configuration.interval, 5, accuracy: 0.001)
    XCTAssertFalse(configuration.repeats)
    XCTAssertEqual(configuration.direction, .reverse)
    XCTAssertFalse(configuration.pausesOnUserInteraction)
    XCTAssertFalse(configuration.pausesWhenOffscreen)
  }
}
