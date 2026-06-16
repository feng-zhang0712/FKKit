import FKUIKit
import XCTest

final class FKCalloutConfigurationTests: XCTestCase {
  func testTooltipDefaultUsesNarrowWidthAndAutoDismiss() {
    let configuration = FKCalloutConfiguration.tooltipDefault()

    XCTAssertEqual(configuration.kind, .tooltip)
    XCTAssertEqual(configuration.maxWidth, 240, accuracy: 0.001)
    XCTAssertEqual(configuration.autoDismissDuration, Optional(3))
    XCTAssertFalse(configuration.tapOutsideToDismiss)
  }

  func testPopoverDefaultKeepsManualDismiss() {
    let configuration = FKCalloutConfiguration.popoverDefault()

    XCTAssertEqual(configuration.kind, .popover)
    XCTAssertNil(configuration.autoDismissDuration)
    XCTAssertTrue(configuration.tapOutsideToDismiss)
  }

  func testMenuDefaultMatchesAnchorWidthAndLeadingAlignment() {
    let configuration = FKCalloutConfiguration.menuDefault()

    XCTAssertEqual(configuration.anchorAlignment, .leading)
    XCTAssertTrue(configuration.matchesAnchorWidth)
  }
}
