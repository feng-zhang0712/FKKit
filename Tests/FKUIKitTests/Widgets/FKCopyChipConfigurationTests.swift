import FKUIKit
import XCTest

final class FKCopyChipConfigurationTests: XCTestCase {
  func testCopyChipSizeResolvesPresetHeights() {
    XCTAssertEqual(FKCopyChipSize.s.height, 28, accuracy: 0.001)
    XCTAssertEqual(FKCopyChipSize.m.height, 36, accuracy: 0.001)
    XCTAssertEqual(FKCopyChipSize.custom(height: 10).height, 24, accuracy: 0.001)
  }

  func testInteractionConfigurationClampsHighlightScale() {
    let interaction = FKCopyChipInteractionConfiguration(highlightScale: 0.5)
    XCTAssertEqual(interaction.highlightScale, 0.85, accuracy: 0.001)
  }

  func testConfigurationEqualityIgnoresAppearanceColors() {
    let first = FKCopyChipConfiguration(
      layout: FKCopyChipLayoutConfiguration(prefix: "Order #"),
      feedback: FKCopyChipFeedbackConfiguration(mode: .hapticOnly)
    )
    let matching = FKCopyChipConfiguration(
      layout: FKCopyChipLayoutConfiguration(prefix: "Order #"),
      feedback: FKCopyChipFeedbackConfiguration(mode: .hapticOnly)
    )

    XCTAssertEqual(first, matching)
  }
}
