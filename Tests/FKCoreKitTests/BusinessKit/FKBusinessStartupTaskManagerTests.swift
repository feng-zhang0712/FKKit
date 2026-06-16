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
}
