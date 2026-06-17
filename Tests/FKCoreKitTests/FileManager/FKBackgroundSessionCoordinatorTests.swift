@testable import FKCoreKit
import XCTest

final class FKBackgroundSessionCoordinatorTests: XCTestCase {
  func testRegisterAndInvokeRunsHandlerOnce() {
    let coordinator = FKBackgroundSessionCoordinator.shared
    let counter = LockedCounter()
    let identifier = "com.fkkit.tests.background.\(UUID().uuidString)"

    coordinator.register({ counter.increment() }, forSessionWithIdentifier: identifier)
    coordinator.invoke(forSessionWithIdentifier: identifier)
    coordinator.invoke(forSessionWithIdentifier: identifier)

    XCTAssertEqual(counter.current, 1)
  }

  func testInvokeUnknownIdentifierIsNoOp() {
    let coordinator = FKBackgroundSessionCoordinator.shared
    XCTAssertNoThrow(coordinator.invoke(forSessionWithIdentifier: "com.fkkit.tests.missing.\(UUID().uuidString)"))
  }

  func testRegisterReplacesExistingHandlerForSameIdentifier() {
    let coordinator = FKBackgroundSessionCoordinator.shared
    let counter = LockedCounter()
    let identifier = "com.fkkit.tests.background.replace.\(UUID().uuidString)"

    coordinator.register({ counter.increment() }, forSessionWithIdentifier: identifier)
    coordinator.register({ counter.increment(by: 5) }, forSessionWithIdentifier: identifier)
    coordinator.invoke(forSessionWithIdentifier: identifier)

    XCTAssertEqual(counter.current, 5)
  }
}
