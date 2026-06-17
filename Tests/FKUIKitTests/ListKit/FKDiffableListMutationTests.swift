@testable import FKUIKit
import XCTest

@MainActor
final class FKDiffableListMutationTests: FKUIKitTestCase {
  private func makeListController() -> FKDiffableTableViewController {
    var configuration = FKListConfiguration()
    configuration.loading.usesSkeletonForInitialLoad = false
    return FKDiffableTableViewController(configuration: configuration)
  }

  func testApplyMutationAppendsItemsToCurrentSnapshot() {
    let controller = makeListController()
    controller.loadViewIfNeeded()
    controller.applySnapshot(
      ListKitTestFixtures.snapshot(items: [
        ListKitTestFixtures.textItem(id: "a", title: "A"),
      ]),
      animatingDifferences: false
    )

    controller.applyMutation(
      .appendItems(
        [ListKitTestFixtures.textItem(id: "b", title: "B")],
        toSection: ListKitTestFixtures.mainSectionID
      ),
      animatingDifferences: false
    )

    XCTAssertEqual(controller.currentSnapshot.totalItemCount, 2)
    XCTAssertEqual(controller.presentationState, .content)
  }

  func testApplyMutationDeletingAllItemsTransitionsToEmptyState() {
    let controller = makeListController()
    controller.loadViewIfNeeded()
    let item = ListKitTestFixtures.textItem(id: "only", title: "Only")
    controller.applySnapshot(
      ListKitTestFixtures.snapshot(items: [item]),
      animatingDifferences: false
    )
    XCTAssertEqual(controller.presentationState, .content)

    controller.applyMutation(
      .deleteItems([item.id]),
      animatingDifferences: false
    )

    XCTAssertEqual(controller.currentSnapshot.totalItemCount, 0)
    XCTAssertEqual(controller.presentationState, .empty)
  }

  func testApplyMutationReloadItemsKeepsSnapshotCount() {
    let controller = makeListController()
    controller.loadViewIfNeeded()
    let item = ListKitTestFixtures.textItem(id: "row", title: "Row")
    controller.applySnapshot(ListKitTestFixtures.snapshot(items: [item]), animatingDifferences: false)

    controller.applyMutation(.reloadItems([item.id]), animatingDifferences: false)

    XCTAssertEqual(controller.currentSnapshot.totalItemCount, 1)
    XCTAssertEqual(controller.presentationState, .content)
  }
}
