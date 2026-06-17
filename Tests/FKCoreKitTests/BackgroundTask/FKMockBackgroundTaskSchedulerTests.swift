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
    let observedExpired = LockedFlag()
    try scheduler.registerAppRefresh(identifier: refreshIdentifier) { handle in
      observedExpired.set(handle.isExpired)
      return !handle.isExpired
    }

    await scheduler.simulateLaunch(identifier: refreshIdentifier, simulateExpiration: true)

    XCTAssertTrue(observedExpired.current)
  }

  func testScheduleProcessingRecordsRequestAfterInstallation() async throws {
    let processingIdentifier = "com.fkkit.test.processing"
    let scheduler = FKMockBackgroundTaskScheduler()
    try scheduler.registerProcessing(identifier: processingIdentifier) { _ in true }
    try scheduler.installRegistrations([
      FKBackgroundTaskRegistration(identifier: processingIdentifier, kind: .processing),
    ])

    let request = FKBackgroundProcessingRequest(identifier: processingIdentifier, requiresNetworkConnectivity: true)
    try await scheduler.scheduleProcessing(request)

    XCTAssertEqual(scheduler.scheduledProcessing.count, 1)
    XCTAssertEqual(scheduler.scheduledProcessing[0].identifier, processingIdentifier)
    XCTAssertTrue(scheduler.scheduledProcessing[0].requiresNetworkConnectivity)
  }

  func testCancelScheduledTaskRemovesPendingRefreshRequest() async throws {
    let scheduler = FKMockBackgroundTaskScheduler()
    try scheduler.registerAppRefresh(identifier: refreshIdentifier) { _ in true }
    try scheduler.installRegistrations([
      FKBackgroundTaskRegistration(identifier: refreshIdentifier, kind: .appRefresh),
    ])
    try await scheduler.scheduleAppRefresh(FKBackgroundAppRefreshRequest(identifier: refreshIdentifier))

    try await scheduler.cancelScheduledTask(withIdentifier: refreshIdentifier)

    XCTAssertTrue(scheduler.scheduledRefresh.isEmpty)
  }

  func testSimulateHandlerOverridesRegisteredHandler() async {
    let scheduler = FKMockBackgroundTaskScheduler()
    let counter = LockedCounter()
    try? scheduler.registerAppRefresh(identifier: refreshIdentifier) { _ in
      counter.increment()
      return true
    }
    scheduler.simulateHandler = { _ in false }

    await scheduler.simulateLaunch(identifier: refreshIdentifier)

    XCTAssertEqual(counter.current, 0)
  }

  func testBeginBackgroundWorkExecutesAsyncClosure() async {
    let application = MockBackgroundApplication()
    let scheduler = FKMockBackgroundTaskScheduler(application: application)
    let counter = LockedCounter()

    _ = scheduler.beginBackgroundWork(name: "test") {
      counter.increment()
    }

    let deadline = Date().addingTimeInterval(1)
    while counter.current == 0, Date() < deadline {
      await Task.yield()
    }

    XCTAssertEqual(counter.current, 1)
    XCTAssertEqual(application.activeTaskCount, 0)
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

private final class LockedFlag: @unchecked Sendable {
  private let lock = NSLock()
  private var value = false

  var current: Bool {
    lock.lock()
    defer { lock.unlock() }
    return value
  }

  func set(_ newValue: Bool) {
    lock.lock()
    value = newValue
    lock.unlock()
  }
}
