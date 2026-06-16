import FKUIKit
import XCTest

final class FKCarouselInteractionConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesStandardNestedScrollPolicy() {
    let configuration = FKCarouselInteractionConfiguration()

    XCTAssertEqual(configuration.nestedScrollPolicy, .standard)
    XCTAssertFalse(configuration.requiresNavigationPopGestureToFail)
    XCTAssertEqual(configuration.nonInteractiveAlpha, 1, accuracy: 0.001)
  }

  func testConfigurationStoresCustomNestedScrollAndAlphaValues() {
    let configuration = FKCarouselInteractionConfiguration(
      nestedScrollPolicy: .failParentUntilCarouselAtEdge,
      requiresNavigationPopGestureToFail: true,
      nonInteractiveAlpha: 0.6
    )

    XCTAssertEqual(configuration.nestedScrollPolicy, .failParentUntilCarouselAtEdge)
    XCTAssertTrue(configuration.requiresNavigationPopGestureToFail)
    XCTAssertEqual(configuration.nonInteractiveAlpha, 0.6, accuracy: 0.001)
  }
}
