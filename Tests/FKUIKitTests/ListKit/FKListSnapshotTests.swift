import FKUIKit
import XCTest

final class FKListSnapshotTests: XCTestCase {
  func testTotalItemCountSumsAllSections() {
    let snapshot = FKListSnapshot(sections: [
      ListKitTestFixtures.section(items: [
        ListKitTestFixtures.textItem(id: "a", title: "A"),
        ListKitTestFixtures.textItem(id: "b", title: "B"),
      ]),
      ListKitTestFixtures.section(items: [
        ListKitTestFixtures.textItem(id: "c", title: "C"),
      ], id: "secondary"),
    ])

    XCTAssertEqual(snapshot.totalItemCount, 3)
  }

  func testItemWithIDReturnsMatchingRow() {
    let item = ListKitTestFixtures.textItem(id: "row-1", title: "One")
    let snapshot = ListKitTestFixtures.snapshot(items: [item])

    XCTAssertEqual(snapshot.item(withID: "row-1"), item)
    XCTAssertNil(snapshot.item(withID: "missing"))
  }

  func testSectionWithIDReturnsMatchingSection() {
    let section = ListKitTestFixtures.section(
      items: [ListKitTestFixtures.textItem(id: "a", title: "A")],
      id: "settings"
    )
    let snapshot = FKListSnapshot(sections: [section])

    XCTAssertEqual(snapshot.section(withID: "settings"), section)
    XCTAssertNil(snapshot.section(withID: "missing"))
  }

  func testItemIDsWithChangedContentDetectsPresetUpdates() {
    let before = ListKitTestFixtures.snapshot(items: [
      ListKitTestFixtures.switchItem(id: "toggle", title: "Wi-Fi", isOn: false),
    ])
    let after = ListKitTestFixtures.snapshot(items: [
      ListKitTestFixtures.switchItem(id: "toggle", title: "Wi-Fi", isOn: true),
    ])

    XCTAssertEqual(after.itemIDsWithChangedContent(comparedTo: before), ["toggle"])
  }

  func testItemIDsWithChangedContentIgnoresUnchangedRows() {
    let unchanged = ListKitTestFixtures.textItem(id: "same", title: "Same")
    let before = ListKitTestFixtures.snapshot(items: [unchanged])
    let after = ListKitTestFixtures.snapshot(items: [unchanged])

    XCTAssertTrue(after.itemIDsWithChangedContent(comparedTo: before).isEmpty)
  }
}
