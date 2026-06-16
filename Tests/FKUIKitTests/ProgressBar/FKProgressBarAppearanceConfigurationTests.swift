import FKUIKit
import XCTest

final class FKProgressBarAppearanceConfigurationTests: XCTestCase {
  func testInitClampsNegativeBorderWidthsToZero() {
    let configuration = FKProgressBarAppearanceConfiguration(
      trackBorderWidth: -2,
      progressBorderWidth: -1
    )

    XCTAssertEqual(configuration.trackBorderWidth, 0, accuracy: 0.001)
    XCTAssertEqual(configuration.progressBorderWidth, 0, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesSolidFillWithoutBuffer() {
    let configuration = FKProgressBarAppearanceConfiguration()

    XCTAssertEqual(configuration.fillStyle, .solid)
    XCTAssertFalse(configuration.showsBuffer)
  }
}
