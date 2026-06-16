import FKUIKit
import XCTest

final class FKListRefreshConfigurationTests: XCTestCase {
  func testInitClampsNegativeLoadMorePreloadOffsetToZero() {
    let configuration = FKListRefreshConfiguration(loadMorePreloadOffset: -40)

    XCTAssertEqual(configuration.loadMorePreloadOffset, 0, accuracy: 0.001)
  }

  func testLoadMoreRefreshConfigurationForwardsTriggerModeAndPreloadOffset() {
    let configuration = FKListRefreshConfiguration(
      loadMoreTriggerMode: .manual,
      loadMorePreloadOffset: 120,
      autohidesLoadMoreFooterWhenNotScrollable: true
    )
    let refresh = configuration.loadMoreRefreshConfiguration()

    XCTAssertEqual(refresh.loadMoreTriggerMode, .manual)
    XCTAssertEqual(refresh.loadMorePreloadOffset, 120, accuracy: 0.001)
    XCTAssertTrue(refresh.autohidesFooterWhenNotScrollable)
  }
}
