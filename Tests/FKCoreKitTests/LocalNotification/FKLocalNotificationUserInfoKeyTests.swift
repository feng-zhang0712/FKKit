import FKCoreKit
import XCTest

final class FKLocalNotificationUserInfoKeyTests: XCTestCase {
  func testStandardKeysUseFKNamespace() {
    XCTAssertEqual(FKLocalNotificationUserInfoKey.deeplinkURL, "fk.deeplink.url")
    XCTAssertEqual(FKLocalNotificationUserInfoKey.routeID, "fk.route.id")
    XCTAssertEqual(FKLocalNotificationUserInfoKey.analyticsEvent, "fk.analytics.event")
  }
}
