import FKUIKit
import XCTest

final class FKMarqueeLabelInteractionConfigurationTests: XCTestCase {
  func testDefaultConfigurationPausesOnPan() {
    let configuration = FKMarqueeLabelInteractionConfiguration()

    XCTAssertTrue(configuration.pausesOnPan)
  }

  func testConfigurationStoresDisabledPanPause() {
    let configuration = FKMarqueeLabelInteractionConfiguration(pausesOnPan: false)

    XCTAssertFalse(configuration.pausesOnPan)
  }
}
