import FKCoreKit
import XCTest

private actor StartupTaskOrderRecorder {
  private var values: [String] = []

  func append(_ value: String) {
    values.append(value)
  }

  func snapshot() -> [String] {
    values
  }
}

private actor StartupTaskCounter {
  private var value = 0

  func increment(by amount: Int = 1) {
    value += amount
  }

  func current() -> Int {
    value
  }
}

final class FKBusinessStartupTaskManagerTests: XCTestCase {
  func testRunAllExecutesTasksInPriorityOrder() async {
    let manager = FKBusinessStartupTaskManager()
    let order = StartupTaskOrderRecorder()

    manager.register(
      FKStartupTask(id: "low", priority: .low) {
        await order.append("low")
      }
    )
    manager.register(
      FKStartupTask(id: "high", priority: .high) {
        await order.append("high")
      }
    )
    manager.register(
      FKStartupTask(id: "normal", priority: .normal) {
        await order.append("normal")
      }
    )

    await manager.runAll()

    let recorded = await order.snapshot()
    XCTAssertEqual(recorded, ["high", "normal", "low"])
  }

  func testRegisterReplacesTaskWithSameIdentifier() async {
    let manager = FKBusinessStartupTaskManager()
    let counter = StartupTaskCounter()

    manager.register(
      FKStartupTask(id: "analytics") {
        await counter.increment()
      }
    )
    manager.register(
      FKStartupTask(id: "analytics") {
        await counter.increment(by: 2)
      }
    )

    await manager.runAll()

    let count = await counter.current()
    XCTAssertEqual(count, 2)
  }

  func testRunAllExecutesTasksSequentially() async {
    let manager = FKBusinessStartupTaskManager()
    actor ConcurrencyProbe {
      private var inFlight = 0
      private(set) var peakConcurrent = 0

      func enter() {
        inFlight += 1
        peakConcurrent = max(peakConcurrent, inFlight)
      }

      func leave() {
        inFlight -= 1
      }

      func peak() -> Int {
        peakConcurrent
      }
    }

    let probe = ConcurrencyProbe()
    for identifier in ["a", "b", "c"] {
      manager.register(
        FKStartupTask(id: identifier) {
          await probe.enter()
          try? await Task.sleep(nanoseconds: 20_000_000)
          await probe.leave()
        }
      )
    }

    await manager.runAll()

    let peak = await probe.peak()
    XCTAssertEqual(peak, 1)
  }

  func testRunAllOrdersEqualPriorityTasksByDelay() async {
    let manager = FKBusinessStartupTaskManager()
    let order = StartupTaskOrderRecorder()

    manager.register(
      FKStartupTask(id: "delayed", priority: .normal, delay: 0.05) {
        await order.append("delayed")
      }
    )
    manager.register(
      FKStartupTask(id: "immediate", priority: .normal, delay: 0) {
        await order.append("immediate")
      }
    )

    await manager.runAll()

    let recorded = await order.snapshot()
    XCTAssertEqual(recorded, ["immediate", "delayed"])
  }
}
