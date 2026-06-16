import FKUIKit
import XCTest

final class FKPresenceIndicatorConfigurationTests: XCTestCase {
  func testInitClampsPulsePeriodToMinimumDuration() {
    let configuration = FKPresenceIndicatorConfiguration(pulsePeriod: 0.5)

    XCTAssertEqual(configuration.pulsePeriod, 1.5, accuracy: 0.001)
  }

  func testDefaultConfigurationUsesMediumSizeWithBorder() {
    let configuration = FKPresenceIndicatorConfiguration()

    XCTAssertEqual(configuration.size, .m)
    XCTAssertTrue(configuration.showsBorder)
    XCTAssertTrue(configuration.pulsesWhenOnline)
  }
}
