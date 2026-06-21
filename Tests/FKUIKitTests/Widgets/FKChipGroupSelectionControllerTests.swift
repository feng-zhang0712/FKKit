@testable import FKUIKit
import XCTest

final class FKChipGroupSelectionControllerTests: XCTestCase {
  func testNoneModeLeavesSelectionUnchanged() {
    let result = FKChipGroupSelectionController.toggledSelection(
      current: ["a"],
      tappedID: "b",
      mode: .none,
      overflowBehavior: .ignoreTap
    )

    XCTAssertEqual(result.selection, ["a"])
    XCTAssertFalse(result.limitReached)
  }

  func testSingleModeSelectsOnlyTappedChip() {
    let result = FKChipGroupSelectionController.toggledSelection(
      current: [],
      tappedID: "b",
      mode: .single,
      overflowBehavior: .ignoreTap
    )

    XCTAssertEqual(result.selection, ["b"])
  }

  func testSingleModeClearsSelectionWhenTappingSelectedChip() {
    let result = FKChipGroupSelectionController.toggledSelection(
      current: ["b"],
      tappedID: "b",
      mode: .single,
      overflowBehavior: .ignoreTap
    )

    XCTAssertTrue(result.selection.isEmpty)
  }

  func testMultipleModeAddsChipWhenUnderCapacity() {
    let result = FKChipGroupSelectionController.toggledSelection(
      current: ["a"],
      tappedID: "b",
      mode: .multiple(max: 2),
      overflowBehavior: .ignoreTap
    )

    XCTAssertEqual(result.selection, ["a", "b"])
    XCTAssertFalse(result.limitReached)
  }

  func testMultipleModeRemovesChipWhenTappingSelectedEntry() {
    let result = FKChipGroupSelectionController.toggledSelection(
      current: ["a", "b"],
      tappedID: "a",
      mode: .multiple(max: 3),
      overflowBehavior: .ignoreTap
    )

    XCTAssertEqual(result.selection, ["b"])
  }

  func testMultipleModeIgnoresOverflowTapByDefault() {
    let result = FKChipGroupSelectionController.toggledSelection(
      current: ["a", "b"],
      tappedID: "c",
      mode: .multiple(max: 2),
      overflowBehavior: .ignoreTap
    )

    XCTAssertEqual(result.selection, ["a", "b"])
    XCTAssertFalse(result.limitReached)
  }

  func testMultipleModeNotifiesWhenOverflowBehaviorIsNotify() {
    let result = FKChipGroupSelectionController.toggledSelection(
      current: ["a", "b"],
      tappedID: "c",
      mode: .multiple(max: 2),
      overflowBehavior: .notify
    )

    XCTAssertEqual(result.selection, ["a", "b"])
    XCTAssertTrue(result.limitReached)
  }

  func testMultipleModeWithoutMaxAllowsUnboundedSelection() {
    let result = FKChipGroupSelectionController.toggledSelection(
      current: ["a", "b", "c"],
      tappedID: "d",
      mode: .multiple(max: nil),
      overflowBehavior: .ignoreTap
    )

    XCTAssertEqual(result.selection, ["a", "b", "c", "d"])
  }
}
