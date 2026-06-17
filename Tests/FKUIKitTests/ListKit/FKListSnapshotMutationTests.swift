@testable import FKUIKit
import XCTest

final class FKListSnapshotMutationTests: XCTestCase {
  func testReplaceMutationReplacesEntireSnapshot() {
    let original = ListKitTestFixtures.snapshot(items: [
      ListKitTestFixtures.textItem(id: "a", title: "A"),
    ])
    let replacement = ListKitTestFixtures.snapshot(items: [
      ListKitTestFixtures.textItem(id: "b", title: "B"),
    ])
    var snapshot = original

    FKListSnapshotApplier.apply(.replace(replacement), to: &snapshot)

    XCTAssertEqual(snapshot, replacement)
  }

  func testAppendItemsAddsRowsToMatchingSection() {
    var snapshot = ListKitTestFixtures.snapshot(items: [
      ListKitTestFixtures.textItem(id: "a", title: "A"),
    ])
    let newItem = ListKitTestFixtures.textItem(id: "b", title: "B")

    FKListSnapshotApplier.apply(
      .appendItems([newItem], toSection: ListKitTestFixtures.mainSectionID),
      to: &snapshot
    )

    XCTAssertEqual(snapshot.totalItemCount, 2)
    XCTAssertEqual(snapshot.item(withID: "b")?.id.rawValue, "b")
  }

  func testInsertItemsInsertsAfterAnchorWhenPresent() {
    var snapshot = ListKitTestFixtures.snapshot(items: [
      ListKitTestFixtures.textItem(id: "a", title: "A"),
      ListKitTestFixtures.textItem(id: "c", title: "C"),
    ])
    let inserted = ListKitTestFixtures.textItem(id: "b", title: "B")

    FKListSnapshotApplier.apply(
      .insertItems([(inserted, after: FKListItemID("a"))], inSection: ListKitTestFixtures.mainSectionID),
      to: &snapshot
    )

    XCTAssertEqual(snapshot.sections.first?.items.map(\.id.rawValue), ["a", "b", "c"])
  }

  func testDeleteItemsRemovesMatchingIDsAcrossSections() {
    var snapshot = FKListSnapshot(sections: [
      ListKitTestFixtures.section(items: [
        ListKitTestFixtures.textItem(id: "a", title: "A"),
        ListKitTestFixtures.textItem(id: "b", title: "B"),
      ]),
      ListKitTestFixtures.section(
        items: [ListKitTestFixtures.textItem(id: "b", title: "B duplicate")],
        id: "secondary"
      ),
    ])

    FKListSnapshotApplier.apply(.deleteItems([FKListItemID("a"), FKListItemID("b")]), to: &snapshot)

    XCTAssertEqual(snapshot.totalItemCount, 0)
  }

  func testDuplicateItemIDsDetectsRepeatedRowIDs() {
    let snapshot = FKListSnapshot(sections: [
      ListKitTestFixtures.section(items: [
        ListKitTestFixtures.textItem(id: "dup", title: "One"),
        ListKitTestFixtures.textItem(id: "dup", title: "Two"),
      ]),
    ])

    XCTAssertEqual(FKListSnapshotApplier.duplicateItemIDs(in: snapshot).map(\.rawValue), ["dup"])
  }
}
