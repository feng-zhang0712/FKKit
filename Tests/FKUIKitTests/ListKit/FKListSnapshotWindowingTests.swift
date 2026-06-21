@testable import FKUIKit
import XCTest

final class FKListSnapshotWindowingTests: XCTestCase {
  private func makeSnapshot(ids: [String]) -> FKListSnapshot {
    ListKitTestFixtures.snapshot(
      items: ids.map { ListKitTestFixtures.textItem(id: $0, title: $0.uppercased()) }
    )
  }

  func testApplyReturnsSnapshotUnchangedWhenWindowingDisabled() {
    let snapshot = makeSnapshot(ids: ["a", "b", "c"])
    let configuration = FKListWindowingConfiguration(isEnabled: false, maxItemCount: 2)

    let result = FKListSnapshotWindowing.apply(to: snapshot, configuration: configuration)

    XCTAssertEqual(result.snapshot.totalItemCount, 3)
    XCTAssertTrue(result.removedItemIDs.isEmpty)
  }

  func testApplyReturnsSnapshotUnchangedWhenUnderMaxItemCount() {
    let snapshot = makeSnapshot(ids: ["a", "b"])
    let configuration = FKListWindowingConfiguration(isEnabled: true, maxItemCount: 5)

    let result = FKListSnapshotWindowing.apply(to: snapshot, configuration: configuration)

    XCTAssertEqual(result.snapshot.totalItemCount, 2)
    XCTAssertTrue(result.removedItemIDs.isEmpty)
  }

  func testApplyRemovesOldestItemsFromHeadAcrossSections() {
    let snapshot = FKListSnapshot(sections: [
      ListKitTestFixtures.section(
        items: [
          ListKitTestFixtures.textItem(id: "s1-a", title: "S1-A"),
          ListKitTestFixtures.textItem(id: "s1-b", title: "S1-B"),
        ],
        id: "first"
      ),
      ListKitTestFixtures.section(
        items: [
          ListKitTestFixtures.textItem(id: "s2-a", title: "S2-A"),
          ListKitTestFixtures.textItem(id: "s2-b", title: "S2-B"),
        ],
        id: "second"
      ),
    ])
    let configuration = FKListWindowingConfiguration(isEnabled: true, maxItemCount: 2)

    let result = FKListSnapshotWindowing.apply(to: snapshot, configuration: configuration)

    XCTAssertEqual(result.snapshot.totalItemCount, 2)
    XCTAssertEqual(result.removedItemIDs.map(\.rawValue), ["s1-a", "s1-b"])
    XCTAssertNil(result.snapshot.item(withID: "s1-a"))
    XCTAssertNil(result.snapshot.item(withID: "s1-b"))
    XCTAssertNotNil(result.snapshot.item(withID: "s2-a"))
    XCTAssertNotNil(result.snapshot.item(withID: "s2-b"))
  }

  func testApplyRemovesEmptySectionsAfterTrimming() {
    let snapshot = FKListSnapshot(sections: [
      ListKitTestFixtures.section(
        items: [ListKitTestFixtures.textItem(id: "old", title: "Old")],
        id: "head"
      ),
      ListKitTestFixtures.section(
        items: [ListKitTestFixtures.textItem(id: "keep", title: "Keep")],
        id: "tail"
      ),
    ])
    let configuration = FKListWindowingConfiguration(isEnabled: true, maxItemCount: 1)

    let result = FKListSnapshotWindowing.apply(to: snapshot, configuration: configuration)

    XCTAssertEqual(result.snapshot.sections.count, 1)
    XCTAssertEqual(result.snapshot.sections[0].id.rawValue, "tail")
    XCTAssertEqual(result.removedItemIDs.map(\.rawValue), ["old"])
  }
}
