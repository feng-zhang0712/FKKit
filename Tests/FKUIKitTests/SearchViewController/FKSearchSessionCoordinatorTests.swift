@testable import FKUIKit
import XCTest

final class FKSearchSessionCoordinatorTests: XCTestCase {
  func testBeginSearchIncrementsGenerationAndReturnsToken() {
    let coordinator = FKSearchSessionCoordinator()

    let first = coordinator.beginSearch()
    let second = coordinator.beginSearch()

    XCTAssertEqual(first, 1)
    XCTAssertEqual(second, 2)
    XCTAssertTrue(coordinator.isCurrent(second))
    XCTAssertFalse(coordinator.isCurrent(first))
  }

  func testCancelAllInvalidatesCurrentGeneration() {
    let coordinator = FKSearchSessionCoordinator()
    let token = coordinator.beginSearch()

    coordinator.cancelAll()

    XCTAssertFalse(coordinator.isCurrent(token))
    XCTAssertTrue(coordinator.isCurrent(coordinator.beginSearch()))
  }

  func testBeginSearchCancelsPreviouslyRegisteredTask() async {
    let coordinator = FKSearchSessionCoordinator()
    let firstToken = coordinator.beginSearch()
    let cancelled = expectation(description: "previous task cancelled")

    coordinator.register(Task {
      do {
        try await Task.sleep(nanoseconds: 500_000_000)
      } catch {
        cancelled.fulfill()
      }
    })

    _ = coordinator.beginSearch()
    await fulfillment(of: [cancelled], timeout: 1.0)

    XCTAssertFalse(coordinator.isCurrent(firstToken))
  }
}
