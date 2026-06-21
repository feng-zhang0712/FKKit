@testable import FKUIKit
import XCTest

final class FKProgressBarLabelFormattingTests: XCTestCase {
  private func makeConfiguration(
    format: FKProgressBarLabelFormat = .percentInteger,
    prefix: String = "",
    suffix: String = ""
  ) -> FKProgressBarConfiguration {
    var configuration = FKProgressBarConfiguration()
    configuration.label.format = format
    configuration.label.valuePrefix = prefix
    configuration.label.valueSuffix = suffix
    configuration.label.logicalMinimum = 0
    configuration.label.logicalMaximum = 100
    return configuration
  }

  func testDisplayStringPercentIntegerRoundsToWholePercent() {
    let configuration = makeConfiguration(format: .percentInteger)

    XCTAssertEqual(
      FKProgressBarLabelFormatting.displayString(progress: 0.456, configuration: configuration),
      "46%"
    )
  }

  func testDisplayStringAppliesPrefixAndSuffix() {
    var configuration = makeConfiguration(format: .percentInteger, prefix: "~", suffix: " done")
    configuration.label.format = .percentInteger

    XCTAssertEqual(
      FKProgressBarLabelFormatting.displayString(progress: 1, configuration: configuration),
      "~100% done"
    )
  }

  func testDisplayStringNormalizedValueUsesFractionDigits() {
    var configuration = makeConfiguration(format: .normalizedValue)
    configuration.label.fractionDigits = 2

    let text = FKProgressBarLabelFormatting.displayString(progress: 0.333, configuration: configuration)

    XCTAssertTrue(text.hasPrefix("0.33") || text.hasPrefix("0,33"))
  }

  func testDisplayStringLogicalRangeValueMapsProgressToRange() {
    var configuration = makeConfiguration(format: .logicalRangeValue)
    configuration.label.logicalMinimum = 10
    configuration.label.logicalMaximum = 20

    let text = FKProgressBarLabelFormatting.displayString(progress: 0.5, configuration: configuration)

    XCTAssertTrue(text.contains("15"))
  }

  func testDisplayStringClampsProgressIntoZeroToOneRange() {
    let configuration = makeConfiguration(format: .percentInteger)

    XCTAssertEqual(
      FKProgressBarLabelFormatting.displayString(progress: 2, configuration: configuration),
      "100%"
    )
    XCTAssertEqual(
      FKProgressBarLabelFormatting.displayString(progress: -1, configuration: configuration),
      "0%"
    )
  }

  func testAccessibilityValueUsesIndeterminateCopyWhenAnimating() {
    let configuration = makeConfiguration()

    let value = FKProgressBarLabelFormatting.accessibilityValue(
      progress: 0.5,
      buffer: 0,
      configuration: configuration,
      isIndeterminate: true
    )

    XCTAssertFalse(value.isEmpty)
  }

  func testAccessibilityValueIncludesBufferWhenShown() {
    var configuration = makeConfiguration(format: .logicalRangeValue)
    configuration.appearance.showsBuffer = true
    configuration.label.logicalMinimum = 0
    configuration.label.logicalMaximum = 100

    let value = FKProgressBarLabelFormatting.accessibilityValue(
      progress: 0.4,
      buffer: 0.8,
      configuration: configuration,
      isIndeterminate: false
    )

    XCTAssertFalse(value.isEmpty)
    XCTAssertNotEqual(
      value,
      FKProgressBarLabelFormatting.accessibilityValue(
        progress: 0.4,
        buffer: 0,
        configuration: configuration,
        isIndeterminate: false
      )
    )
  }

  func testAccessibilityValueUsesPercentFormatWithoutBuffer() {
    let configuration = makeConfiguration(format: .percentInteger)

    let value = FKProgressBarLabelFormatting.accessibilityValue(
      progress: 0.75,
      buffer: 0,
      configuration: configuration,
      isIndeterminate: false
    )

    XCTAssertFalse(value.isEmpty)
  }
}
