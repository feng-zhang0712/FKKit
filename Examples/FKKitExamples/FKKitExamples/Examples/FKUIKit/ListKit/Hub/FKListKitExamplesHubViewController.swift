import UIKit

/// Entry list for FKListKit demos (`Support/`, `Scenarios/`).
final class FKListKitExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "Table · data & refresh",
      rows: [
        Row(
          title: "Feed · refresh & load more",
          subtitle: "FKListDataProviding · pagination · FKRefresh · delegate hooks",
          make: { FKListKitFeedRefreshLoadMoreExampleViewController() }
        ),
        Row(
          title: "Host-driven initial load",
          subtitle: "loadInitialContent(handler:) without dataProvider",
          make: { FKListKitHostDrivenLoadExampleViewController() }
        ),
        Row(
          title: "Snapshot mutations",
          subtitle: "appendItems · deleteItems · reloadItems · reloadSections",
          make: { FKListKitSnapshotMutationsExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Table · presentation states",
      rows: [
        Row(
          title: "Skeleton initial load",
          subtitle: "FKListSkeletonPolicy.fullOverlay until first applySnapshot",
          make: { FKListKitSkeletonInitialLoadExampleViewController() }
        ),
        Row(
          title: "Empty state",
          subtitle: "Zero-item snapshot · FKEmptyState overlay · retry",
          make: { FKListKitEmptyStateExampleViewController() }
        ),
        Row(
          title: "Error & retry",
          subtitle: "Failed fetch · error overlay · preservesContentOnError option",
          make: { FKListKitErrorRetryExampleViewController() }
        ),
        Row(
          title: "Empty policy · replace content",
          subtitle: "FKListEmptyPresentationPolicy.replaceContent",
          make: { FKListKitEmptyPolicyReplaceExampleViewController() }
        ),
        Row(
          title: "Empty policy · inline zero rows",
          subtitle: "FKListEmptyPresentationPolicy.inlineZeroRows",
          make: { FKListKitEmptyPolicyInlineExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Table · presets & interaction",
      rows: [
        Row(
          title: "Settings · multi-section presets",
          subtitle: "All preset rows · section headers · switch/checkbox handlers",
          make: { FKListKitSettingsMultisectionExampleViewController() }
        ),
        Row(
          title: "Swipe actions",
          subtitle: "Leading pin · trailing destructive · handler registry",
          make: { FKListKitSwipeActionsExampleViewController() }
        ),
        Row(
          title: "Selection modes",
          subtitle: "single · multiple · programmatic select · preservesSelection",
          make: { FKListKitSelectionModesExampleViewController() }
        ),
        Row(
          title: "Search filter",
          subtitle: "Debounced UISearchBar · applySnapshot filtered",
          make: { FKListKitSearchFilterExampleViewController() }
        ),
        Row(
          title: "Icon · remote image row",
          subtitle: "FKListIconRow · FKImageView · prefetch delegate",
          make: { FKListKitIconRemoteRowExampleViewController() }
        ),
        Row(
          title: "Custom cell",
          subtitle: "FKListTableCellConfigurable · payload store · register(_:forPayloadType:)",
          make: { FKListKitCustomCellExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Collection",
      rows: [
        Row(
          title: "Collection · list preset",
          subtitle: "FKDiffableCollectionViewController · .list layout",
          make: { FKListKitCollectionListExampleViewController() }
        ),
        Row(
          title: "Collection · grid preset",
          subtitle: ".grid(columns:spacing:) · preset cells",
          make: { FKListKitCollectionGridExampleViewController() }
        ),
        Row(
          title: "Collection · inset grouped",
          subtitle: ".insetGroupedList · section headers",
          make: { FKListKitCollectionInsetGroupedExampleViewController() }
        ),
      ]
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ListKit"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    sections.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sections[section].title
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.numberOfLines = 0
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = sections[indexPath.section].rows[indexPath.row].make()
    navigationController?.pushViewController(vc, animated: true)
  }
}
