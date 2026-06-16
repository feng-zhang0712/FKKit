import FKCoreKit
import XCTest

final class FKDebouncerTests: XCTestCase {
  private var queue: DispatchQueue!
  private var debouncer: FKDebouncer!

  override func setUp() {
    super.setUp()
    queue = DispatchQueue(label: "com.fkkit.tests.debouncer")
    debouncer = FKDebouncer(interval: 0.05, queue: queue)
  }

  override func tearDown() {
    debouncer.cancelPending()
    debouncer = nil
    queue = nil
    super.tearDown()
  }

  func testSignalCoalescesToLastAction() async throws {
    let counter = LockedCounter()

    debouncer.signal {
      counter.increment()
    }
    debouncer.signal {
      counter.increment()
    }
    debouncer.signal {
      counter.increment()
    }

    try await Task.sleep(nanoseconds: 150_000_000)
    XCTAssertEqual(counter.current, 1)
  }

  func testCancelPendingPreventsScheduledAction() async throws {
    let counter = LockedCounter()

    debouncer.signal {
      counter.increment()
    }
    debouncer.cancelPending()

    try await Task.sleep(nanoseconds: 150_000_000)
    XCTAssertEqual(counter.current, 0)
  }
}
