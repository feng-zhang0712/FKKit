import FKUIKit
import XCTest

final class FKImageViewAppearanceConfigurationTests: XCTestCase {
  func testDefaultConfigurationUsesAspectFillAndCrossDissolve() {
    let configuration = FKImageViewAppearanceConfiguration()

    XCTAssertEqual(configuration.cornerStyle, .none)
    XCTAssertEqual(configuration.contentMode, .scaleAspectFill)
    if case .crossDissolve(let duration) = configuration.successTransition {
      XCTAssertEqual(duration, 0.2, accuracy: 0.001)
    } else {
      XCTFail("Expected crossDissolve success transition")
    }
  }

  func testConfigurationStoresCustomCornerStyleAndHighlightAlpha() {
    let configuration = FKImageViewAppearanceConfiguration(
      cornerStyle: .fixed(8),
      adjustsImageWhenHighlighted: true,
      highlightedAlpha: 0.5
    )

    if case .fixed(let radius) = configuration.cornerStyle {
      XCTAssertEqual(radius, 8, accuracy: 0.001)
    } else {
      XCTFail("Expected fixed corner style")
    }
    XCTAssertTrue(configuration.adjustsImageWhenHighlighted)
    XCTAssertEqual(configuration.highlightedAlpha, 0.5, accuracy: 0.001)
  }
}
