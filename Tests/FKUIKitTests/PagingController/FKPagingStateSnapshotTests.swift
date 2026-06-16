import FKUIKit
import XCTest

final class FKPagingStateSnapshotTests: XCTestCase {
  func testSnapshotEquatableAcrossFields() {
    let lhs = FKPagingStateSnapshot(
      selectedIndex: 1,
      fromIndex: 1,
      toIndex: 2,
      progress: 0.4,
      phase: .dragging,
      transitionToken: 3
    )
    let rhs = FKPagingStateSnapshot(
      selectedIndex: 1,
      fromIndex: 1,
      toIndex: 2,
      progress: 0.4,
      phase: .dragging,
      transitionToken: 3
    )
    XCTAssertEqual(lhs, rhs)
  }

  func testIdlePhaseDiffersFromProgrammaticSwitch() {
    XCTAssertNotEqual(FKPagingPhase.idle, FKPagingPhase.programmaticSwitch)
  }
}
