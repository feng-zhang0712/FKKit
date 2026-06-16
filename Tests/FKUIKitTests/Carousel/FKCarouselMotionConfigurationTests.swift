import FKUIKit
import XCTest

final class FKCarouselMotionConfigurationTests: XCTestCase {
  func testDefaultConfigurationAnimatesIndicatorDotsWithoutHaptics() {
    let configuration = FKCarouselMotionConfiguration()

    XCTAssertEqual(configuration.imageCrossFadeDuration, 0.25, accuracy: 0.001)
    XCTAssertTrue(configuration.animatesIndicatorDots)
    XCTAssertFalse(configuration.playsPageChangeHaptic)
  }

  func testConfigurationStoresCustomCrossFadeDurationAndHapticFlag() {
    let configuration = FKCarouselMotionConfiguration(
      imageCrossFadeDuration: 0.4,
      animatesIndicatorDots: false,
      playsPageChangeHaptic: true
    )

    XCTAssertEqual(configuration.imageCrossFadeDuration, 0.4, accuracy: 0.001)
    XCTAssertFalse(configuration.animatesIndicatorDots)
    XCTAssertTrue(configuration.playsPageChangeHaptic)
  }
}
