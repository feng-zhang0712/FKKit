import FKUIKit
import XCTest

final class FKSearchIconConfigurationTests: XCTestCase {
  func testDefaultConfigurationShowsIconAtSeventeenPointSize() {
    let configuration = FKSearchIconConfiguration()

    XCTAssertFalse(configuration.isHidden)
    XCTAssertNil(configuration.image)
    XCTAssertEqual(configuration.pointSize, 17, accuracy: 0.001)
  }

  func testConfigurationStoresHiddenFlagAndCustomPointSize() {
    let configuration = FKSearchIconConfiguration(isHidden: true, pointSize: 20)

    XCTAssertTrue(configuration.isHidden)
    XCTAssertEqual(configuration.pointSize, 20, accuracy: 0.001)
  }
}
