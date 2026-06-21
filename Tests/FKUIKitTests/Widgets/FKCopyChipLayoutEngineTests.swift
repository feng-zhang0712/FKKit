@testable import FKUIKit
import UIKit
import XCTest

final class FKCopyChipLayoutEngineTests: XCTestCase {
  private func makeLayout(
    truncation: FKCopyChipTruncation = .none,
    prefix: String? = nil
  ) -> FKCopyChipLayoutConfiguration {
    FKCopyChipLayoutConfiguration(prefix: prefix, truncation: truncation)
  }

  func testDisplayStringUsesFullTextWhenTruncationIsNone() {
    let layout = makeLayout()

    XCTAssertEqual(
      FKCopyChipTextFormatter.displayString(text: "ORDER-12345", layout: layout),
      "ORDER-12345"
    )
  }

  func testDisplayStringAppliesTailTruncation() {
    let layout = makeLayout(truncation: .tail(maxCharacters: 4))

    XCTAssertEqual(
      FKCopyChipTextFormatter.displayString(text: "ABCDEFGH", layout: layout),
      "ABCD"
    )
  }

  func testDisplayStringAppliesMiddleTruncation() {
    let layout = makeLayout(truncation: .middle(prefixLength: 2, suffixLength: 2))

    let formatted = FKCopyChipTextFormatter.displayString(text: "1234567890", layout: layout)

    XCTAssertTrue(formatted.hasPrefix("12"))
    XCTAssertTrue(formatted.hasSuffix("90"))
  }

  func testDisplayStringPrependsNonEmptyPrefix() {
    let layout = makeLayout(prefix: "ID: ")

    XCTAssertEqual(
      FKCopyChipTextFormatter.displayString(text: "42", layout: layout),
      "ID: 42"
    )
  }

  func testAccessibilitySummaryMatchesDisplayString() {
    let layout = makeLayout(truncation: .tail(maxCharacters: 3), prefix: "Ref ")
    let text = "ABCDEF"

    XCTAssertEqual(
      FKCopyChipTextFormatter.accessibilitySummary(text: text, layout: layout),
      FKCopyChipTextFormatter.displayString(text: text, layout: layout)
    )
  }

  func testLayoutPlacesIconOnTrailingEdgeForLeftToRight() {
    let input = FKCopyChipLayoutEngine.Input(
      displayText: "Copy",
      font: .systemFont(ofSize: 14),
      height: 36,
      horizontalPadding: 12,
      iconSpacing: 8,
      iconPointSize: 16
    )

    let metrics = FKCopyChipLayoutEngine.layout(input, layoutDirection: .leftToRight)

    XCTAssertEqual(metrics.size.height, 36, accuracy: 0.001)
    XCTAssertEqual(metrics.cornerRadius, 18, accuracy: 0.001)
    XCTAssertEqual(metrics.textFrame.minX, 12, accuracy: 0.001)
    XCTAssertEqual(metrics.iconFrame.maxX, metrics.size.width - 12, accuracy: 0.001)
    XCTAssertGreaterThanOrEqual(metrics.size.width, 36)
  }

  func testLayoutMirrorsIconAndTextForRightToLeft() {
    let input = FKCopyChipLayoutEngine.Input(
      displayText: "Copy",
      font: .systemFont(ofSize: 14),
      height: 36,
      horizontalPadding: 12,
      iconSpacing: 8,
      iconPointSize: 16
    )

    let metrics = FKCopyChipLayoutEngine.layout(input, layoutDirection: .rightToLeft)

    XCTAssertEqual(metrics.iconFrame.minX, 12, accuracy: 0.001)
    XCTAssertGreaterThan(metrics.textFrame.minX, metrics.iconFrame.maxX)
  }

  func testPillFrameAlignsLeadingForLeftToRight() {
    let metrics = FKCopyChipLayoutEngine.Metrics(
      size: CGSize(width: 120, height: 36),
      cornerRadius: 18,
      textFrame: .zero,
      iconFrame: .zero
    )
    let bounds = CGRect(x: 0, y: 0, width: 200, height: 44)

    let frame = FKCopyChipLayoutEngine.pillFrame(
      metrics: metrics,
      in: bounds,
      layoutDirection: .leftToRight
    )

    XCTAssertEqual(frame.origin.x, 0, accuracy: 0.001)
    XCTAssertEqual(frame.size.width, 120, accuracy: 0.001)
    XCTAssertEqual(frame.midY, bounds.midY, accuracy: 0.001)
  }

  func testPillFrameAlignsTrailingForRightToLeft() {
    let metrics = FKCopyChipLayoutEngine.Metrics(
      size: CGSize(width: 120, height: 36),
      cornerRadius: 18,
      textFrame: .zero,
      iconFrame: .zero
    )
    let bounds = CGRect(x: 0, y: 0, width: 200, height: 44)

    let frame = FKCopyChipLayoutEngine.pillFrame(
      metrics: metrics,
      in: bounds,
      layoutDirection: .rightToLeft
    )

    XCTAssertEqual(frame.maxX, bounds.width, accuracy: 0.001)
  }

  func testPillFrameClampsWidthToBounds() {
    let metrics = FKCopyChipLayoutEngine.Metrics(
      size: CGSize(width: 300, height: 36),
      cornerRadius: 18,
      textFrame: .zero,
      iconFrame: .zero
    )
    let bounds = CGRect(x: 0, y: 0, width: 200, height: 44)

    let frame = FKCopyChipLayoutEngine.pillFrame(
      metrics: metrics,
      in: bounds,
      layoutDirection: .leftToRight
    )

    XCTAssertEqual(frame.size.width, 200, accuracy: 0.001)
  }
}
