import FKUIKit
import XCTest

final class FKButtonFeedbackConfigurationTests: XCTestCase {
  func testHapticsConfigurationDefaultsKeepFeedbackDisabled() {
    let configuration = FKButtonHapticsConfiguration()

    XCTAssertFalse(configuration.onPressDown)
    XCTAssertFalse(configuration.onPrimaryAction)
    XCTAssertEqual(configuration.impactStyle, .light)
  }

  func testSoundConfigurationDefaultsKeepFeedbackDisabled() {
    let configuration = FKButtonSoundFeedbackConfiguration()

    XCTAssertFalse(configuration.onPressDown)
    XCTAssertFalse(configuration.onPrimaryAction)
    if case let .system(soundID) = configuration.pressDownSound {
      XCTAssertEqual(soundID, 1104)
    } else {
      XCTFail("Expected default system sound")
    }
  }

  func testPointerConfigurationClampsHoverAlphaMultiplierIntoZeroThroughOne() {
    let configuration = FKButtonPointerConfiguration(hoverAlphaMultiplier: 1.5)
    XCTAssertEqual(configuration.hoverAlphaMultiplier, 1, accuracy: 0.001)

    let clampedLow = FKButtonPointerConfiguration(hoverAlphaMultiplier: -0.2)
    XCTAssertEqual(clampedLow.hoverAlphaMultiplier, 0, accuracy: 0.001)
  }
}
