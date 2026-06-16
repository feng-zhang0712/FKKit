import FKCoreKit
import XCTest

final class FKBackgroundTaskRegistrationTests: XCTestCase {
  func testRegistrationStoresIdentifierAndKind() {
    let registration = FKBackgroundTaskRegistration(identifier: "com.example.refresh", kind: .appRefresh)

    XCTAssertEqual(registration.identifier, "com.example.refresh")
    XCTAssertEqual(registration.kind, .appRefresh)
  }

  func testRegistrationIsHashableByIdentifierAndKind() {
    let refresh = FKBackgroundTaskRegistration(identifier: "task.a", kind: .appRefresh)
    let processing = FKBackgroundTaskRegistration(identifier: "task.a", kind: .processing)

    XCTAssertEqual(refresh, refresh)
    XCTAssertNotEqual(refresh, processing)
  }
}
