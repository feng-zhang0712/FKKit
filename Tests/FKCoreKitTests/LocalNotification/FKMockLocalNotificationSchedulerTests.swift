import FKCoreKit
import XCTest

final class FKMockLocalNotificationSchedulerTests: XCTestCase {
  private func makeRequest(
    identifier: String = "order.reminder.1",
    title: String = "Reminder",
    body: String = "Your order is ready."
  ) -> FKLocalNotificationRequest {
    FKLocalNotificationRequest(
      identifier: identifier,
      content: FKLocalNotificationContent(title: title, body: body),
      trigger: .immediate
    )
  }

  func testScheduleStoresRequestInMemory() async throws {
    let scheduler = FKMockLocalNotificationScheduler()
    let request = makeRequest()

    try await scheduler.schedule(request)

    XCTAssertEqual(scheduler.scheduled.count, 1)
    XCTAssertEqual(scheduler.scheduled[0].identifier, request.identifier)
  }

  func testScheduleReplacesExistingRequestWithSameIdentifier() async throws {
    let scheduler = FKMockLocalNotificationScheduler()
    try await scheduler.schedule(makeRequest(body: "First"))
    try await scheduler.schedule(makeRequest(body: "Updated"))

    XCTAssertEqual(scheduler.scheduled.count, 1)
    XCTAssertEqual(scheduler.scheduled[0].content.body, "Updated")
  }

  func testScheduleThrowsWhenAuthorizationDenied() async {
    let scheduler = FKMockLocalNotificationScheduler()
    scheduler.authorizationGranted = false

    do {
      try await scheduler.schedule(makeRequest())
      XCTFail("Expected notAuthorized error")
    } catch let error as FKLocalNotificationError {
      XCTAssertEqual(error, .notAuthorized)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testScheduleThrowsForEmptyIdentifier() async {
    let scheduler = FKMockLocalNotificationScheduler()

    do {
      try await scheduler.schedule(makeRequest(identifier: "   "))
      XCTFail("Expected invalidContent error")
    } catch let error as FKLocalNotificationError {
      guard case .invalidContent = error else {
        XCTFail("Expected invalidContent, got \(error)")
        return
      }
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testCancelPendingRemovesScheduledRequest() async throws {
    let scheduler = FKMockLocalNotificationScheduler()
    let request = makeRequest()
    try await scheduler.schedule(request)

    await scheduler.cancelPending(withIdentifier: request.identifier)

    XCTAssertTrue(scheduler.scheduled.isEmpty)
  }

  func testSimulateResponseInvokesHandlerOnMainActor() async throws {
    let scheduler = FKMockLocalNotificationScheduler()
    let request = makeRequest()
    try await scheduler.schedule(request)

    let collector = LockedStringCollector()
    scheduler.responseHandler = { response in
      collector.append(response.requestIdentifier)
    }

    scheduler.simulateResponse(requestIdentifier: request.identifier)

    let deadline = Date().addingTimeInterval(1)
    while collector.snapshot.isEmpty, Date() < deadline {
      await Task.yield()
    }

    XCTAssertEqual(collector.snapshot, [request.identifier])
  }
}
