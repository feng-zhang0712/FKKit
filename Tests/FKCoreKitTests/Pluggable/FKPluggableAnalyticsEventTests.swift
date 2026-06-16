import FKCoreKit
import XCTest

final class FKPluggableAnalyticsEventTests: XCTestCase {
  func testInitStoresNameTimestampAndParameters() {
    let event = FKPluggableAnalyticsEvent(
      id: "evt-1",
      name: "button_click",
      timestamp: 100,
      parameters: ["screen": "home"]
    )

    XCTAssertEqual(event.id, "evt-1")
    XCTAssertEqual(event.name, "button_click")
    XCTAssertEqual(event.timestamp, 100, accuracy: 0.001)
    XCTAssertEqual(event.parameters["screen"], "home")
  }

  func testHashableUsesIdentifiableFields() {
    let first = FKPluggableAnalyticsEvent(id: "same", name: "tap", timestamp: 1)
    let second = FKPluggableAnalyticsEvent(id: "same", name: "tap", timestamp: 1)

    XCTAssertEqual(first, second)
  }
}
