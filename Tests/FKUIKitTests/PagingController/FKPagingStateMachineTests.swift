@testable import FKUIKit
import XCTest

@MainActor
final class FKPagingStateMachineTests: FKUIKitTestCase {
  func testInitialIndexIsClampedToZero() {
    let machine = FKPagingStateMachine(initialIndex: -3)

    XCTAssertEqual(machine.snapshot.selectedIndex, 0)
    XCTAssertEqual(machine.snapshot.phase, .idle)
  }

  func testBeginProgrammaticSwitchUpdatesSnapshotAndToken() {
    let machine = FKPagingStateMachine(initialIndex: 0)
    let token = machine.beginProgrammaticSwitch(from: 0, to: 2)

    XCTAssertEqual(token, 1)
    XCTAssertEqual(machine.snapshot.phase, .programmaticSwitch)
    XCTAssertEqual(machine.snapshot.fromIndex, 0)
    XCTAssertEqual(machine.snapshot.toIndex, 2)
  }

  func testDraggingProgressIsClampedBetweenZeroAndOne() {
    let machine = FKPagingStateMachine(initialIndex: 1)
    machine.updateDraggingProgress(1.5, from: 1, to: 2)

    XCTAssertEqual(machine.snapshot.phase, .dragging)
    XCTAssertEqual(machine.snapshot.progress, 1)

    machine.updateDraggingProgress(-0.2, from: 1, to: 2)
    XCTAssertEqual(machine.snapshot.progress, 0)
  }

  func testSettleReturnsToIdleWithSelectedIndex() {
    let machine = FKPagingStateMachine(initialIndex: 0)
    machine.beginProgrammaticSwitch(from: 0, to: 3)
    machine.settle(at: 3)

    XCTAssertEqual(machine.snapshot.selectedIndex, 3)
    XCTAssertEqual(machine.snapshot.phase, .idle)
    XCTAssertNil(machine.snapshot.fromIndex)
    XCTAssertNil(machine.snapshot.toIndex)
  }

  func testInvalidateTransitionTokenIncrementsMonotonicCounter() {
    let machine = FKPagingStateMachine(initialIndex: 0)
    _ = machine.beginProgrammaticSwitch(from: 0, to: 1)
    let next = machine.invalidateTransitionToken()

    XCTAssertEqual(next, 2)
  }
}
