import FKCoreKit
import XCTest

final class FKLocalNotificationManagerConfigurationTests: XCTestCase {
  func testDefaultConfigurationDoesNotAutoInstallDelegate() {
    let configuration = FKLocalNotificationManagerConfiguration.default

    XCTAssertEqual(configuration.defaultPresentation, .standard)
    XCTAssertFalse(configuration.automaticallyInstallDelegate)
    XCTAssertTrue(configuration.logSchedulingFailures)
    XCTAssertFalse(configuration.routeDeeplinkBeforeResponseHandler)
  }

  func testConfigurationStoresCustomPresentationAndRoutingFlags() {
    let configuration = FKLocalNotificationManagerConfiguration(
      defaultPresentation: [.banner, .sound],
      automaticallyInstallDelegate: true,
      logSchedulingFailures: false,
      routeDeeplinkBeforeResponseHandler: true
    )

    XCTAssertEqual(configuration.defaultPresentation, [.banner, .sound])
    XCTAssertTrue(configuration.automaticallyInstallDelegate)
    XCTAssertFalse(configuration.logSchedulingFailures)
    XCTAssertTrue(configuration.routeDeeplinkBeforeResponseHandler)
  }
}
