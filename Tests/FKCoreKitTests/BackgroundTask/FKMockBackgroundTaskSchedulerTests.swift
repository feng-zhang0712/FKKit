import FKCoreKit
import XCTest

final class FKMockBackgroundTaskSchedulerTests: XCTestCase {
  private let refreshIdentifier = "com.fkkit.test.refresh"

  func testScheduleAppRefreshRecordsRequestAfterInstallation() async throws {
    let scheduler = FKMockBackgroundTaskScheduler()
    try scheduler.registerAppRefresh(identifier: refreshIdentifier) { _ in true }
    try scheduler.installRegistrations([
      FKBackgroundTaskRegistration(identifier: refreshIdentifier, kind: .appRefresh),
    ])

    let earliest = Date(timeIntervalSince1970: 1_700_000_000)
    try await scheduler.scheduleAppRefresh(
      FKBackgroundAppRefreshRequest(identifier: refreshIdentifier, earliestBeginDate: earliest)
    )

    XCTAssertEqual(scheduler.scheduledRefresh.count, 1)
    XCTAssertEqual(scheduler.scheduledRefresh[0].identifier, refreshIdentifier)
    XCTAssertEqual(scheduler.scheduledRefresh[0].earliestBeginDate, earliest)
  }

  func testScheduleThrowsWhenNotInstalled() async {
    let scheduler = FKMockBackgroundTaskScheduler()
    try? scheduler.registerAppRefresh(identifier: refreshIdentifier) { _ in true }

    do {
      try await scheduler.scheduleAppRefresh(FKBackgroundAppRefreshRequest(identifier: refreshIdentifier))
      XCTFail("Expected notInstalled error")
    } catch let error as FKBackgroundTaskError {
      XCTAssertEqual(error, .notInstalled)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testSimulateLaunchInvokesRegisteredHandler() async throws {
    let scheduler = FKMockBackgroundTaskScheduler()
    let counter = LockedCounter()
    try scheduler.registerAppRefresh(identifier: refreshIdentifier) { _ in
      counter.increment()
      return true
    }

    await scheduler.simulateLaunch(identifier: refreshIdentifier)

    XCTAssertEqual(counter.current, 1)
  }

  func testSimulateLaunchReturnsFalseWhenTaskExpired() async throws {
    let scheduler = FKMockBackgroundTaskScheduler()
    try scheduler.registerAppRefresh(identifier: refreshIdentifier) { handle in
      !handle.isExpired
    }

    await scheduler.simulateLaunch(identifier: refreshIdentifier, simulateExpiration: true)
  }

  func testRegisterDuplicateIdentifierThrows() {
    let scheduler = FKMockBackgroundTaskScheduler()
    try? scheduler.registerAppRefresh(identifier: refreshIdentifier) { _ in true }

    XCTAssertThrowsError(
      try scheduler.registerAppRefresh(identifier: refreshIdentifier) { _ in true }
    ) { error in
      guard let taskError = error as? FKBackgroundTaskError else {
        XCTFail("Expected FKBackgroundTaskError")
        return
      }
      XCTAssertEqual(taskError, .duplicateRegistration(refreshIdentifier))
    }
  }
}
