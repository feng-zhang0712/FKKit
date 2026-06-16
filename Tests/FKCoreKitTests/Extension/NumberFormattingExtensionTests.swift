import FKCoreKit
import XCTest

final class NumberFormattingExtensionTests: XCTestCase {
  func testZeroPaddedPadsLeadingZerosToRequestedLength() {
    XCTAssertEqual(7.fk_zeroPadded(toLength: 4), "0007")
    XCTAssertEqual(123.fk_zeroPadded(toLength: 2), "123")
  }

  func testDecimalTruncatedDropsFractionBeyondScale() {
    let value = Decimal(string: "12.349")!

    XCTAssertEqual(value.fk_truncated(scale: 2), Decimal(string: "12.34"))
  }

  func testDoubleFormattedPercentUsesPercentStyle() {
    let locale = Locale(identifier: "en_US_POSIX")
    let formatted = 0.125.fk_formattedPercent(fractionDigits: 1, locale: locale)

    XCTAssertTrue(formatted.contains("12.5"))
    XCTAssertTrue(formatted.contains("%"))
  }
}
