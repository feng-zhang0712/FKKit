import FKUIKit
import UIKit

/// Demonstrates subclass hooks ``configurePresetCell(_:at:with:)`` and ``makeEmptyStateConfiguration(for:)``.
final class FKListKitAdvancedHooksExampleViewController: FKDiffableTableViewController {
  init() {
    var config = FKListDefaults.defaultConfiguration
    config.empty.scenario = .noFavorites
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
    title = "Advanced Hooks"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Toggle empty",
      primaryAction: UIAction { [weak self] _ in self?.toggleEmpty() }
    )
    applySnapshot(buildContentSnapshot(), animatingDifferences: false)
  }

  override func reloadInitialContent() {
    applySnapshot(buildContentSnapshot(), animatingDifferences: true)
  }

  override func configurePresetCell(
    _ cell: FKListPresetTableCell,
    at indexPath: IndexPath,
    with item: FKListItem
  ) {
    cell.accessoryType = item.id.rawValue.hasPrefix("highlight") ? .checkmark : .none
  }

  override func makeEmptyStateConfiguration(for state: FKListPresentationState) -> FKEmptyStateConfiguration? {
    guard case .empty = state else { return nil }
    var model = FKEmptyStateConfiguration.scenario(configuration.empty.scenario)
    model.phase = .empty
    model.content.title = "Custom empty via hook"
    model.content.description = "makeEmptyStateConfiguration(for:) overrides default copy."
    return model.withPrimaryAction("Show content")
  }

  private func toggleEmpty() {
    if currentSnapshot.totalItemCount == 0 {
      applySnapshot(buildContentSnapshot(), animatingDifferences: true)
    } else {
      applySnapshot(FKListSnapshot(), animatingDifferences: true)
    }
  }

  private func buildContentSnapshot() -> FKListSnapshot {
    FKListSnapshot(items: [
      FKListItem.text(id: "highlight-1", title: "Hook adds checkmark accessory"),
      FKListItem.text(id: "plain-1", title: "Plain preset row"),
      FKListItem.subtitle(id: "plain-2", title: "Subtitle row", subtitle: "No hook accessory"),
    ])
  }
}
