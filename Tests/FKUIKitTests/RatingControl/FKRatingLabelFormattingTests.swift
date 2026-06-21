@testable import FKUIKit
import XCTest

@MainActor
final class FKRatingLabelFormattingTests: XCTestCase {
  func testLabelTextReturnsNilWhenPlacementIsNone() {
    var configuration = FKRatingConfiguration()
    configuration.layout.labelPlacement = .none

    XCTAssertNil(FKRatingLabelFormatting.labelText(value: 4.5, configuration: configuration))
  }

  func testLabelTextUsesCustomTextWhenProvided() {
    var configuration = FKRatingConfiguration()
    configuration.layout.labelPlacement = .trailing
    configuration.label.customText = "Excellent"

    XCTAssertEqual(
      FKRatingLabelFormatting.labelText(value: 3.0, configuration: configuration),
      "Excellent"
    )
  }

  func testLabelTextAppliesPrefixAndSuffixAroundFormattedValue() {
    var configuration = FKRatingConfiguration()
    configuration.layout.labelPlacement = .bottom
    configuration.label.valuePrefix = "Score "
    configuration.label.valueSuffix = "/5"

    XCTAssertEqual(
      FKRatingLabelFormatting.labelText(value: 4.0, configuration: configuration),
      "Score 4/5"
    )
  }

  func testAccessibilityValueUsesConfiguredFormat() {
    var configuration = FKRatingConfiguration()
    configuration.accessibility.valueFormat = "%@ of %@ stars"

    let value = FKRatingLabelFormatting.accessibilityValue(
      value: 3.5,
      maximumValue: 5,
      configuration: configuration
    )

    XCTAssertEqual(value, "3.5 of 5 stars")
  }

  func testLabelSizeIsZeroWhenLabelHidden() {
    var configuration = FKRatingConfiguration()
    configuration.layout.labelPlacement = .none

    XCTAssertEqual(
      FKRatingLabelFormatting.labelSize(value: 4.0, configuration: configuration),
      .zero
    )
  }

  func testLabelSizeIsNonZeroWhenLabelVisible() {
    var configuration = FKRatingConfiguration()
    configuration.layout.labelPlacement = .trailing
    configuration.label.valuePrefix = "Score "

    let size = FKRatingLabelFormatting.labelSize(value: 4.0, configuration: configuration)

    XCTAssertGreaterThan(size.width, 0)
    XCTAssertGreaterThan(size.height, 0)
  }
}
