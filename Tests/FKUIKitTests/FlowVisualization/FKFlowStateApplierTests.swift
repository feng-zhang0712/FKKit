@testable import FKUIKit
import XCTest

final class FKFlowStateApplierTests: XCTestCase {
  func testResolvedItemsReturnsInputWhenCurrentIndexMissing() {
    let items = [
      FKFlowStepItem(id: "1", title: "One", state: .upcoming),
      FKFlowStepItem(id: "2", title: "Two", state: .upcoming),
    ]

    XCTAssertEqual(FKFlowStateApplier.resolvedItems(from: items, currentStepIndex: nil), items)
    XCTAssertEqual(FKFlowStateApplier.resolvedItems(from: items, currentStepIndex: -1), items)
    XCTAssertEqual(FKFlowStateApplier.resolvedItems(from: items, currentStepIndex: 99), items)
  }

  func testResolvedItemsAppliesCompletedCurrentAndUpcomingStates() {
    let items = [
      FKFlowStepItem(id: "1", title: "One", state: .upcoming),
      FKFlowStepItem(id: "2", title: "Two", state: .upcoming),
      FKFlowStepItem(id: "3", title: "Three", state: .upcoming),
    ]

    let resolved = FKFlowStateApplier.resolvedItems(from: items, currentStepIndex: 1)

    XCTAssertEqual(resolved[0].state, .completed)
    XCTAssertEqual(resolved[1].state, .current)
    XCTAssertEqual(resolved[2].state, .upcoming)
  }

  func testResolvedItemsPreservesExplicitErrorSkippedAndDisabledStates() {
    let items = [
      FKFlowStepItem(id: "1", title: "One", state: .completed),
      FKFlowStepItem(id: "2", title: "Two", state: .error),
      FKFlowStepItem(id: "3", title: "Three", state: .skipped),
      FKFlowStepItem(id: "4", title: "Four", state: .disabled),
    ]

    let resolved = FKFlowStateApplier.resolvedItems(from: items, currentStepIndex: 1)

    XCTAssertEqual(resolved[1].state, .error)
    XCTAssertEqual(resolved[2].state, .skipped)
    XCTAssertEqual(resolved[3].state, .disabled)
  }
}
