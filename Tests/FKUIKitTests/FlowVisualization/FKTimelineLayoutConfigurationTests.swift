import FKUIKit
import XCTest

final class FKTimelineLayoutConfigurationTests: XCTestCase {
  func testInitClampsSpacingAndLineLimits() {
    let configuration = FKTimelineLayoutConfiguration(
      rowSpacing: -4,
      railSpacing: 1,
      titleNumberOfLines: 0,
      subtitleNumberOfLines: -2,
      captionNumberOfLines: 0
    )

    XCTAssertEqual(configuration.rowSpacing, 0, accuracy: 0.001)
    XCTAssertEqual(configuration.railSpacing, 4, accuracy: 0.001)
    XCTAssertEqual(configuration.titleNumberOfLines, 1)
    XCTAssertEqual(configuration.subtitleNumberOfLines, 1)
    XCTAssertEqual(configuration.captionNumberOfLines, 1)
  }

  func testDefaultLayoutUsesVerticalLeadingRailAndAbsoluteTimestamps() {
    let configuration = FKTimelineLayoutConfiguration()

    XCTAssertEqual(configuration.layout, .verticalLeadingRail)
    XCTAssertEqual(configuration.timestampStyle, .absolute)
    XCTAssertFalse(configuration.scrollable)
  }
}
