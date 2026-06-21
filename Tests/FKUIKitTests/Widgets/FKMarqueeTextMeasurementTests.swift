@testable import FKUIKit
import XCTest

@MainActor
final class FKMarqueeTextMeasurementTests: XCTestCase {
  private let font = UIFont.systemFont(ofSize: 16)

  func testSingleLineWidthReturnsZeroForEmptyText() {
    XCTAssertEqual(FKMarqueeTextMeasurement.singleLineWidth(for: "", font: font), 0)
  }

  func testSingleLineWidthIsPositiveForNonEmptyText() {
    let width = FKMarqueeTextMeasurement.singleLineWidth(for: "Marquee label", font: font)

    XCTAssertGreaterThan(width, 0)
  }

  func testFitsSingleLineReturnsTrueForShortTextWithinWidth() {
    XCTAssertTrue(
      FKMarqueeTextMeasurement.fitsSingleLine(text: "OK", font: font, width: 200)
    )
  }

  func testFitsSingleLineReturnsFalseForLongTextWithinNarrowWidth() {
    let longText = String(repeating: "Wide ", count: 20)

    XCTAssertFalse(
      FKMarqueeTextMeasurement.fitsSingleLine(text: longText, font: font, width: 40)
    )
  }
}
