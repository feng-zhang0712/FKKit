import FKUIKit
import XCTest

final class FKProgressBarLabelConfigurationTests: XCTestCase {
  func testFractionDigitsClampedToSupportedRange() {
    let low = FKProgressBarLabelConfiguration(fractionDigits: -3)
    let high = FKProgressBarLabelConfiguration(fractionDigits: 99)

    XCTAssertEqual(low.fractionDigits, 0)
    XCTAssertEqual(high.fractionDigits, 6)
  }

  func testPaddingClampedToNonNegativeValue() {
    let configuration = FKProgressBarLabelConfiguration(padding: -10)
    XCTAssertEqual(configuration.padding, 0, accuracy: 0.001)
  }

  func testDefaultFormatUsesPercentIntegerMode() {
    let configuration = FKProgressBarLabelConfiguration()
    XCTAssertEqual(configuration.format, .percentInteger)
    XCTAssertEqual(configuration.placement, .none)
  }
}
