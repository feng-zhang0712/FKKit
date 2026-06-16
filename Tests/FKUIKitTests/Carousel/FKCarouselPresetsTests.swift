import FKUIKit
import XCTest

final class FKCarouselPresetsTests: XCTestCase {
  func testCardPeekEnablesAutoScrollAndInfiniteLoop() {
    let configuration = FKCarouselPresets.cardPeek()

    XCTAssertTrue(configuration.layout.isInfiniteLoopEnabled)
    XCTAssertTrue(configuration.autoScroll.isEnabled)
    XCTAssertEqual(configuration.autoScroll.interval, 4, accuracy: 0.001)
  }

  func testFullWidthEnablesAutoScrollWhenIntervalProvided() {
    let configuration = FKCarouselPresets.fullWidth(autoScrollInterval: 2.5)

    XCTAssertTrue(configuration.autoScroll.isEnabled)
    XCTAssertEqual(configuration.autoScroll.interval, 2.5, accuracy: 0.001)
  }

  func testOnboardingDisablesAutoScrollAndInfiniteLoop() {
    let configuration = FKCarouselPresets.onboarding()

    XCTAssertFalse(configuration.layout.isInfiniteLoopEnabled)
    XCTAssertFalse(configuration.autoScroll.isEnabled)
  }
}
