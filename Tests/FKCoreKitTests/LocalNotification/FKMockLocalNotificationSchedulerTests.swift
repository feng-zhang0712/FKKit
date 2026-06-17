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

  func testScheduleBatchStoresAllRequests() async throws {
    let scheduler = FKMockLocalNotificationScheduler()
    let requests = [
      makeRequest(identifier: "a"),
      makeRequest(identifier: "b"),
    ]

    try await scheduler.schedule(requests)

    XCTAssertEqual(scheduler.scheduled.count, 2)
    XCTAssertEqual(Set(scheduler.scheduled.map(\.identifier)), Set(["a", "b"]))
  }

  func testCancelAllPendingClearsScheduledRequests() async throws {
    let scheduler = FKMockLocalNotificationScheduler()
    try await scheduler.schedule(makeRequest(identifier: "a"))
    try await scheduler.schedule(makeRequest(identifier: "b"))

    await scheduler.cancelAllPending()

    XCTAssertTrue(scheduler.scheduled.isEmpty)
  }

  func testSimulateDeliveryMovesRequestFromPendingToDelivered() async throws {
    let scheduler = FKMockLocalNotificationScheduler()
    let request = makeRequest(identifier: "delivery.test")
    try await scheduler.schedule(request)

    scheduler.simulateDelivery(identifier: request.identifier)

    XCTAssertTrue(scheduler.scheduled.isEmpty)

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

  func testShouldThrowOverridesNextScheduleAttempt() async {
    let scheduler = FKMockLocalNotificationScheduler()
    scheduler.shouldThrow = .systemError("simulated")

    do {
      try await scheduler.schedule(makeRequest())
      XCTFail("Expected systemError")
    } catch let error as FKLocalNotificationError {
      guard case let .systemError(message) = error else {
        XCTFail("Expected systemError, got \(error)")
        return
      }
      XCTAssertEqual(message, "simulated")
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }
}
