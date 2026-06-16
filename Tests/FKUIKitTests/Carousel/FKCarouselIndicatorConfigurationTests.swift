import FKUIKit
import XCTest

final class FKCarouselIndicatorConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesDotsOverlayBottomPlacement() {
    let configuration = FKCarouselIndicatorConfiguration()

    XCTAssertEqual(configuration.style, .dots)
    if case .overlayBottom(let inset) = configuration.placement {
      XCTAssertEqual(inset, 12, accuracy: 0.001)
    } else {
      XCTFail("Expected overlayBottom placement")
    }
    XCTAssertTrue(configuration.hidesForSinglePage)
  }

  func testConfigurationStoresCustomDotMetricsAndColors() {
    let configuration = FKCarouselIndicatorConfiguration(
      style: .bar,
      dotDiameter: 10,
      dotSpacing: 6,
      activeColor: .red,
      inactiveColor: .gray
    )

    XCTAssertEqual(configuration.style, .bar)
    XCTAssertEqual(configuration.dotDiameter, 10, accuracy: 0.001)
    XCTAssertEqual(configuration.dotSpacing, 6, accuracy: 0.001)
    XCTAssertEqual(configuration.activeColor, .red)
    XCTAssertEqual(configuration.inactiveColor, .gray)
  }
}
