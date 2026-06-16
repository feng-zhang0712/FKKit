import FKCoreKit
import XCTest

final class FKThrottlerTests: XCTestCase {
  private var queue: DispatchQueue!
  private var throttler: FKThrottler!

  override func setUp() {
    super.setUp()
    queue = DispatchQueue(label: "com.fkkit.tests.throttler")
    throttler = FKThrottler(interval: 1.0, queue: queue)
  }

  override func tearDown() {
    throttler.reset()
    throttler = nil
    queue = nil
    super.tearDown()
  }

  func testThrottleDropsCallsInsideInterval() async throws {
    let counter = LockedCounter()

    throttler.throttle {
      counter.increment()
    }
    throttler.throttle {
      counter.increment()
    }

    try await Task.sleep(nanoseconds: 50_000_000)
    XCTAssertEqual(counter.current, 1)
  }

  func testResetAllowsImmediateNextInvocation() async throws {
    let counter = LockedCounter()

    throttler.throttle {
      counter.increment()
    }

    try await Task.sleep(nanoseconds: 50_000_000)
    XCTAssertEqual(counter.current, 1)

    throttler.reset()
    throttler.throttle {
      counter.increment()
    }

    try await Task.sleep(nanoseconds: 50_000_000)
    XCTAssertEqual(counter.current, 2)
  }
}
