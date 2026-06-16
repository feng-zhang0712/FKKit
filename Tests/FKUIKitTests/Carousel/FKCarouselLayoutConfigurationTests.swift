import FKUIKit
import XCTest

final class FKCarouselLayoutConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesFullPageAspectRatioLayout() {
    let configuration = FKCarouselLayoutConfiguration()

    XCTAssertEqual(configuration.layoutMode, .fullPage)
    if case .aspectRatio(let ratio) = configuration.heightStrategy {
      XCTAssertEqual(ratio, 16.0 / 9.0, accuracy: 0.001)
    } else {
      XCTFail("Expected aspectRatio height strategy")
    }
    XCTAssertTrue(configuration.clipsToBounds)
  }

  func testConfigurationStoresCustomLayoutModeAndInfiniteLoopFlag() {
    let configuration = FKCarouselLayoutConfiguration(
      layoutMode: .fixedPageWidth(280),
      heightStrategy: .fixed(180),
      isInfiniteLoopEnabled: true
    )

    if case .fixedPageWidth(let width) = configuration.layoutMode {
      XCTAssertEqual(width, 280, accuracy: 0.001)
    } else {
      XCTFail("Expected fixedPageWidth layout mode")
    }
    if case .fixed(let height) = configuration.heightStrategy {
      XCTAssertEqual(height, 180, accuracy: 0.001)
    } else {
      XCTFail("Expected fixed height strategy")
    }
    XCTAssertTrue(configuration.isInfiniteLoopEnabled)
  }
}
