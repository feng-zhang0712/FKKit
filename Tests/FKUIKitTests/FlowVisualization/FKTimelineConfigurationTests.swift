import FKUIKit
import XCTest

final class FKTimelineConfigurationTests: XCTestCase {
  func testDefaultConfigurationComposesNestedFlowConfigurations() {
    let configuration = FKTimelineConfiguration()

    XCTAssertEqual(configuration.layout.layout, .verticalLeadingRail)
    XCTAssertFalse(configuration.interaction.allowsSelection)
    XCTAssertEqual(configuration.motion.timing, .default)
  }

  func testConfigurationStoresCustomTimestampStyle() {
    var configuration = FKTimelineConfiguration()
    configuration.layout.timestampStyle = .relative

    XCTAssertEqual(configuration.layout.timestampStyle, .relative)
  }
}
