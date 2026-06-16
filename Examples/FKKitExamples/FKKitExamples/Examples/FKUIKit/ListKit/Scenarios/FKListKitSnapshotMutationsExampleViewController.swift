import FKUIKit
import UIKit

/// Demonstrates incremental ``applyMutation(_:animatingDifferences:)`` APIs.
final class FKListKitSnapshotMutationsExampleViewController: FKDiffableTableViewController {
  private var nextID = 4

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Snapshot Mutations"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Actions",
      primaryAction: nil,
      menu: UIMenu(children: [
        UIAction(title: "Append row") { [weak self] _ in self?.appendRow() },
        UIAction(title: "Insert after first") { [weak self] _ in self?.insertAfterFirst() },
        UIAction(title: "Delete last") { [weak self] _ in self?.deleteLast() },
        UIAction(title: "Reconfigure first") { [weak self] _ in self?.reconfigureFirst() },
        UIAction(title: "Reload first item") { [weak self] _ in self?.reloadFirst() },
        UIAction(title: "Reload section") { [weak self] _ in self?.reloadSection() },
        UIAction(title: "Replace snapshot") { [weak self] _ in self?.replaceSnapshot() },
      ])
    )
    applySnapshot(initialSnapshot(), animatingDifferences: false)
  }

  private func initialSnapshot() -> FKListSnapshot {
    FKListSnapshot(sections: [
      FKListSection(
        id: "demo",
        items: (1 ... 3).map { FKListItem.text(id: FKListItemID("item-\($0)"), title: "Row \($0)") },
        header: .title("Mutation target section")
      ),
    ])
  }

  private func appendRow() {
    let id = FKListItemID("item-\(nextID)")
    nextID += 1
    applyMutation(.appendItems([FKListItem.text(id: id, title: "Appended \(id.rawValue)")], toSection: "demo"))
  }

  private func deleteLast() {
    guard let last = currentSnapshot.section(withID: "demo")?.items.last else { return }
    applyMutation(.deleteItems([last.id]))
  }

  private func reloadFirst() {
    guard let first = currentSnapshot.section(withID: "demo")?.items.first else { return }
    applyMutation(.reloadItems([first.id]))
  }

  private func reconfigureFirst() {
    guard let first = currentSnapshot.section(withID: "demo")?.items.first else { return }
    applyMutation(.reconfigureItems([first.id]), animatingDifferences: false)
  }

  private func reloadSection() {
    applyMutation(.reloadSections(["demo"]))
  }

  private func insertAfterFirst() {
    guard let first = currentSnapshot.section(withID: "demo")?.items.first else { return }
    let id = FKListItemID("item-\(nextID)")
    nextID += 1
    applyMutation(
      .insertItems(
        [(FKListItem.text(id: id, title: "Inserted \(id.rawValue)"), after: first.id)],
        inSection: "demo"
      )
    )
  }

  private func replaceSnapshot() {
    let replacement = FKListSnapshot(sections: [
      FKListSection(
        id: "demo",
        items: [
          FKListItem.text(id: "replaced-a", title: "Replaced row A"),
          FKListItem.text(id: "replaced-b", title: "Replaced row B"),
        ],
        header: .title("Replaced section content")
      ),
    ])
    applyMutation(.replace(replacement))
  }
}
