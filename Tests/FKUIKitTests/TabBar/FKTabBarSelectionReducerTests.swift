@testable import FKUIKit
import XCTest

final class FKTabBarSelectionReducerTests: XCTestCase {
  private func reduce(
    selectedIndex: Int = 0,
    previousIndex: Int? = nil,
    phase: FKTabBarSwitchPhase = .idle,
    event: FKTabBarSelectionEvent,
    count: Int
  ) -> FKTabBarSelectionReducer.Output {
    let snapshot = FKTabBarSelectionReducerSnapshot(
      selectedIndex: selectedIndex,
      previousIndex: previousIndex,
      phase: phase
    )
    return FKTabBarSelectionReducer.reduce(snapshot: snapshot, event: event, count: count)
  }

  func testUserTapUpdatesSelectedIndex() {
    let output = reduce(event: .userTap(2), count: 4)

    XCTAssertEqual(output.snapshot.selectedIndex, 2)
    XCTAssertEqual(output.snapshot.previousIndex, 0)
    XCTAssertEqual(output.snapshot.phase, .settled)
    XCTAssertEqual(output.change, .selected(from: 0, to: 2))
  }

  func testUserTapOnCurrentIndexEmitsReselectedChange() {
    let output = reduce(selectedIndex: 1, event: .userTap(1), count: 4)

    XCTAssertEqual(output.snapshot.selectedIndex, 1)
    XCTAssertEqual(output.change, .reselected(1))
  }

  func testGestureProgressMarksSwitchingPhaseWithoutChangingIndex() {
    let output = reduce(selectedIndex: 1, event: .gestureProgress(from: 1, to: 2, progress: 0.4), count: 4)

    XCTAssertEqual(output.snapshot.selectedIndex, 1)
    XCTAssertEqual(output.snapshot.phase, .switching)
    XCTAssertEqual(output.change, .progress(from: 1, to: 2, progress: 0.4))
  }

  func testItemsChangedClampsSelectedIndexWhenTabCountShrinks() {
    let output = reduce(selectedIndex: 4, event: .itemsChanged(count: 3), count: 3)

    XCTAssertEqual(output.snapshot.selectedIndex, 2)
    XCTAssertEqual(output.change, .selected(from: 4, to: 2))
  }
}
