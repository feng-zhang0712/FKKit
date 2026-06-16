import FKUIKit
import XCTest

final class FKCarouselConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesCollapseEmptyStatePolicy() {
    let configuration = FKCarouselConfiguration()

    XCTAssertEqual(configuration.layout.layoutMode, .fullPage)
    XCTAssertTrue(configuration.paging.isScrollEnabled)
    XCTAssertEqual(configuration.emptyState, .collapse)
  }

  func testConfigurationStoresCustomEmptyStateScenario() {
    let configuration = FKCarouselConfiguration(emptyState: .showEmptyState(.noFavorites))

    if case .showEmptyState(let scenario) = configuration.emptyState {
      XCTAssertEqual(scenario, .noFavorites)
    } else {
      XCTFail("Expected showEmptyState policy")
    }
  }
}
