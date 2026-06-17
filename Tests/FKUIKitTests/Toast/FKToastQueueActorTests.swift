@testable import FKUIKit
import XCTest

private final class MockToastClock: FKToastClock, @unchecked Sendable {
  private let lock = NSLock()
  private var current = Date(timeIntervalSince1970: 1_000)

  func now() -> Date {
    lock.lock()
    defer { lock.unlock() }
    return current
  }

  func advance(by interval: TimeInterval) {
    lock.lock()
    current = current.addingTimeInterval(interval)
    lock.unlock()
  }
}

final class FKToastQueueActorTests: XCTestCase {
  private func makeRequest(
    id: UUID = UUID(),
    message: String,
    priority: FKToastPriority = .normal,
    queue: FKToastQueueConfiguration = .init(),
    createdAt: Date
  ) -> FKToastRequest {
    var configuration = FKToastConfiguration()
    configuration.priority = priority
    configuration.queue = queue
    return FKToastRequest(
      id: id,
      content: .message(message),
      icon: nil,
      configuration: configuration,
      hooks: FKToastLifecycleHooks(),
      actionHandler: nil,
      secondaryActionHandler: nil,
      createdAt: createdAt
    )
  }

  func testClaimNextPrefersHigherPriorityWaitingRequests() async {
    let actor = FKToastQueueActor()
    let now = Date()
    let low = makeRequest(message: "low", priority: .low, createdAt: now)
    let high = makeRequest(message: "high", priority: .high, createdAt: now)

    _ = await actor.enqueue(low)
    _ = await actor.enqueue(high)

    let claimed = await actor.claimNext(maxCount: 1)
    XCTAssertEqual(claimed.count, 1)
    if case let .message(message) = claimed[0].content {
      XCTAssertEqual(message, "high")
    } else {
      XCTFail("Expected message content")
    }
  }

  func testCoalescePolicyDropsDuplicateWithinDeduplicationWindow() async {
    let clock = MockToastClock()
    let actor = FKToastQueueActor(clock: clock)
    var queue = FKToastQueueConfiguration()
    queue.arrivalPolicy = .coalesce
    queue.deduplicationWindow = 5

    let first = makeRequest(message: "Saved", queue: queue, createdAt: clock.now())
    _ = await actor.enqueue(first)
    _ = await actor.enqueue(makeRequest(message: "Saved", queue: queue, createdAt: clock.now()))

    let claimed = await actor.claimNext(maxCount: 1)
    XCTAssertEqual(claimed.count, 1)
    await actor.markDismissed(id: first.id)

    clock.advance(by: 6)
    _ = await actor.enqueue(makeRequest(message: "Saved", queue: queue, createdAt: clock.now()))
    let secondClaim = await actor.claimNext(maxCount: 1)
    XCTAssertEqual(secondClaim.count, 1)
  }

  func testReplaceCurrentPolicyKeepsOnlyLatestWaitingRequest() async {
    let actor = FKToastQueueActor()
    var queue = FKToastQueueConfiguration()
    queue.arrivalPolicy = .replaceCurrent
    let now = Date()

    _ = await actor.enqueue(makeRequest(message: "first", queue: queue, createdAt: now))
    _ = await actor.enqueue(makeRequest(message: "second", queue: queue, createdAt: now))
    let latest = makeRequest(message: "third", queue: queue, createdAt: now)
    _ = await actor.enqueue(latest)

    let claimed = await actor.claimNext(maxCount: 1)
    XCTAssertEqual(claimed.map(\.id), [latest.id])
  }

  func testDropNewPolicyAcceptsFirstRequestWhenQueueIsEmpty() async {
    let actor = FKToastQueueActor()
    var queue = FKToastQueueConfiguration()
    queue.arrivalPolicy = .dropNew
    let request = makeRequest(message: "first", queue: queue, createdAt: Date())

    _ = await actor.enqueue(request)

    let claimed = await actor.claimNext(maxCount: 1)
    XCTAssertEqual(claimed.map(\.id), [request.id])
  }

  func testDropNewPolicyDiscardsIncomingRequestWhileQueueIsActive() async {
    let actor = FKToastQueueActor()
    var queue = FKToastQueueConfiguration()
    queue.arrivalPolicy = .dropNew
    let now = Date()

    let first = makeRequest(message: "queued", queue: queue, createdAt: now)
    _ = await actor.enqueue(first)
    _ = await actor.claimNext(maxCount: 1)
    _ = await actor.enqueue(makeRequest(message: "dropped", queue: queue, createdAt: now))

    let claimed = await actor.claimNext(maxCount: 1)
    XCTAssertTrue(claimed.isEmpty)
    if case let .message(message) = await actor.request(for: first.id)?.content {
      XCTAssertEqual(message, "queued")
    } else {
      XCTFail("Expected first toast to remain displayed")
    }
  }

  func testPriorityPreemptionReturnsIncomingRequestWhenDisplayingLowerPriority() async {
    let actor = FKToastQueueActor()
    var queue = FKToastQueueConfiguration()
    queue.allowPriorityPreemption = true
    let now = Date()

    let low = makeRequest(message: "low", priority: .low, queue: queue, createdAt: now)
    _ = await actor.enqueue(low)
    _ = await actor.claimNext(maxCount: 1)

    let high = makeRequest(message: "high", priority: .high, queue: queue, createdAt: now)
    let preempted = await actor.enqueue(high)

    XCTAssertEqual(preempted?.id, high.id)
  }

  func testClearRemovesWaitingAndReturnsDisplayedIdentifiers() async {
    let actor = FKToastQueueActor()
    let now = Date()
    let first = makeRequest(message: "first", createdAt: now)
    let second = makeRequest(message: "second", createdAt: now)

    _ = await actor.enqueue(first)
    _ = await actor.enqueue(second)
    _ = await actor.claimNext(maxCount: 1)

    let clearedIDs = await actor.clear()
    XCTAssertEqual(Set(clearedIDs), Set([first.id]))
    let remaining = await actor.claimNext(maxCount: 2)
    XCTAssertTrue(remaining.isEmpty)
  }
}
