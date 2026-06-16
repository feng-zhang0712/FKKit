import FKUIKit
import XCTest

final class FKCarouselPagingConfigurationTests: XCTestCase {
  func testDefaultConfigurationEnablesScrollingAndProgressReporting() {
    let configuration = FKCarouselPagingConfiguration()

    XCTAssertTrue(configuration.isScrollEnabled)
    XCTAssertEqual(configuration.decelerationRate, .normal)
    XCTAssertEqual(configuration.pageChangeThreshold, 0.5, accuracy: 0.001)
    XCTAssertTrue(configuration.reportsScrollProgress)
  }

  func testConfigurationStoresCustomThresholdAndScrollFlags() {
    let configuration = FKCarouselPagingConfiguration(
      isScrollEnabled: false,
      pageChangeThreshold: 0.35,
      reportsScrollProgress: false
    )

    XCTAssertFalse(configuration.isScrollEnabled)
    XCTAssertEqual(configuration.pageChangeThreshold, 0.35, accuracy: 0.001)
    XCTAssertFalse(configuration.reportsScrollProgress)
  }
}
