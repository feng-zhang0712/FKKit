import FKUIKit
import XCTest

final class FKChipConfigurationTests: XCTestCase {
  func testLayoutConfigurationDefaultsToMediumSize() {
    let layout = FKChipLayoutConfiguration()
    XCTAssertEqual(layout.size, .m)
    XCTAssertEqual(layout.horizontalPadding, 14, accuracy: 0.001)
  }

  func testInteractionConfigurationClampsHighlightScaleAndHitSide() {
    let interaction = FKChipInteractionConfiguration(
      highlightScale: 0.5,
      removeButtonHitSide: 10
    )

    XCTAssertEqual(interaction.highlightScale, 0.85, accuracy: 0.001)
    XCTAssertEqual(interaction.removeButtonHitSide, 44, accuracy: 0.001)
  }

  func testConfigurationEqualityComparesLayoutInteractionAndAccessibility() {
    let first = FKChipConfiguration(
      layout: FKChipLayoutConfiguration(size: .s),
      interaction: FKChipInteractionConfiguration(highlightScale: 0.95),
      accessibility: FKChipAccessibilityConfiguration(customLabel: "Filter")
    )
    let matching = FKChipConfiguration(
      layout: FKChipLayoutConfiguration(size: .s),
      interaction: FKChipInteractionConfiguration(highlightScale: 0.95),
      accessibility: FKChipAccessibilityConfiguration(customLabel: "Filter")
    )
    let different = FKChipConfiguration(
      accessibility: FKChipAccessibilityConfiguration(customLabel: "Choice")
    )

    XCTAssertEqual(first, matching)
    XCTAssertNotEqual(first, different)
  }
}
