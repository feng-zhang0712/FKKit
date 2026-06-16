import FKUIKit
import XCTest

final class FKTabBarSelectionSnapshotTests: XCTestCase {
  func testSnapshotStoresSelectionTransitionMetadata() {
    let snapshot = FKTabBarSelectionSnapshot(
      selectedIndex: 2,
      previousIndex: 1,
      phase: .switching,
      selectedItemID: "explore"
    )

    XCTAssertEqual(snapshot.selectedIndex, 2)
    XCTAssertEqual(snapshot.previousIndex, 1)
    XCTAssertEqual(snapshot.phase, .switching)
    XCTAssertEqual(snapshot.selectedItemID, "explore")
  }

  func testSnapshotDefaultsToIdlePhaseWithoutPreviousIndex() {
    let snapshot = FKTabBarSelectionSnapshot(selectedIndex: 0)

    XCTAssertEqual(snapshot.phase, .idle)
    XCTAssertNil(snapshot.previousIndex)
    XCTAssertNil(snapshot.selectedItemID)
  }
}
