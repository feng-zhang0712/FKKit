import FKUIKit
import XCTest

final class FKRefreshConfigurationTests: XCTestCase {
  func testInitClampsThresholdsAndTimingValues() {
    let configuration = FKRefreshConfiguration(
      triggerThreshold: 5,
      expandedHeight: 10,
      collapseDuration: -1,
      messageFontSize: 4,
      loadMorePreloadOffset: -8,
      automaticEndDelay: -2
    )

    XCTAssertEqual(configuration.triggerThreshold, 20, accuracy: 0.001)
    XCTAssertEqual(configuration.expandedHeight, 20, accuracy: 0.001)
    XCTAssertEqual(configuration.collapseDuration, 0, accuracy: 0.001)
    XCTAssertEqual(configuration.messageFontSize, 8, accuracy: 0.001)
    XCTAssertEqual(configuration.loadMorePreloadOffset, 0, accuracy: 0.001)
    XCTAssertEqual(configuration.automaticEndDelay, 0, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesHorizontalContentLayout() {
    let configuration = FKRefreshConfiguration.default

    XCTAssertEqual(configuration.defaultContentLayout, .horizontal)
    XCTAssertTrue(configuration.shouldKeepExpandedWhileRefreshing)
    XCTAssertEqual(configuration.loadMoreTriggerMode, .automatic)
  }
}
