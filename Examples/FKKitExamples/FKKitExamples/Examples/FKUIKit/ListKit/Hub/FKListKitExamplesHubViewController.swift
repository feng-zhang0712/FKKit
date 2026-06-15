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
          title: "Windowing",
          subtitle: "FKListWindowingConfiguration · trim oldest items on load-more",
          make: { FKListKitWindowingExampleViewController() }
        ),
        Row(
          title: "Feed · complex reference",
          subtitle: "Custom cell · prefetch · reconfigure · FKListHeightCache · visibility",
          make: { FKListKitComplexFeedReferenceExampleViewController() }
        ),
        Row(
          title: "Feed · optimized",
          subtitle: "FKListDefaults.feedConfiguration · no load-more animation · prefetch on",
          make: { FKListKitFeedOptimizedExampleViewController() }
        ),
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
          subtitle: "append · insert · delete · reload · replace",
          make: { FKListKitSnapshotMutationsExampleViewController() }
        ),
        Row(
          title: "Refresh edge cases",
          subtitle: "clearsSnapshotOnRefreshStart · refreshFailureKeepsContent",
          make: { FKListKitRefreshEdgeCasesExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Table · presentation states",
      rows: [
        Row(
          title: "Skeleton · preset rows",
          subtitle: "FKListSkeletonPolicy.presetRows · FKListSkeletonPlaceholderTableCell",
          make: { FKListKitSkeletonPresetRowsExampleViewController() }
        ),
        Row(
          title: "Skeleton initial load",
          subtitle: "FKListSkeletonPolicy.fullOverlay until first applySnapshot",
          make: { FKListKitSkeletonInitialLoadExampleViewController() }
        ),
        Row(
          title: "Skeleton · visible cells",
          subtitle: "Default FKListSkeletonPolicy.visibleCells overlay",
          make: { FKListKitSkeletonVisibleCellsExampleViewController() }
        ),
        Row(
          title: "Empty state",
          subtitle: "Zero-item snapshot · FKEmptyState overlay · retry",
          make: { FKListKitEmptyStateExampleViewController() }
        ),
        Row(
          title: "Error & retry",
          subtitle: "Failed fetch · error overlay · preservesContentOnError = false",
          make: { FKListKitErrorRetryExampleViewController() }
        ),
        Row(
          title: "Error · preserved content",
          subtitle: "preservesContentOnError = true · rows stay under overlay",
          make: { FKListKitErrorPreservedContentExampleViewController() }
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
          subtitle: "All preset rows · SF Symbol leading · checkmark · metadata",
          make: { FKListKitSettingsMultisectionExampleViewController() }
        ),
        Row(
          title: "Swipe actions",
          subtitle: "Leading pin · trailing destructive · handler registry",
          make: { FKListKitSwipeActionsExampleViewController() }
        ),
        Row(
          title: "Selection modes",
          subtitle: "single · deselectOnSecondTap · multiple · FKListDelegate",
          make: { FKListKitSelectionModesExampleViewController() }
        ),
        Row(
          title: "Search filter",
          subtitle: "Debounced UISearchBar · applySnapshot filtered · see SearchViewController hub for FKKit path",
          make: { FKListKitSearchFilterExampleViewController() }
        ),
        Row(
          title: "Icon · remote image row",
          subtitle: "FKListIconRow · FKImageView(profile: .listCell) · FKImageLoader prefetch",
          make: { FKListKitIconRemoteRowExampleViewController() }
        ),
        Row(
          title: "Custom cell",
          subtitle: "FKListTableCellConfigurable · payload store · register(_:forPayloadType:)",
          make: { FKListKitCustomCellExampleViewController() }
        ),
        Row(
          title: "Row height",
          subtitle: "FKListRowHeightPolicy.fixed · rowHeightProvider override",
          make: { FKListKitRowHeightExampleViewController() }
        ),
        Row(
          title: "SwiftUI bridge",
          subtitle: "FKDiffableTableViewControllerRepresentable",
          make: { FKListKitSwiftUIBridgeExampleViewController() }
        ),
        Row(
          title: "Cell visibility",
          subtitle: "FKListDelegate willDisplay · didEndDisplaying",
          make: { FKListKitCellVisibilityExampleViewController() }
        ),
        Row(
          title: "Reconfigure items",
          subtitle: "FKListSnapshotMutation.reconfigureItems · in-place accessory update",
          make: { FKListKitReconfigureItemsExampleViewController() }
        ),
        Row(
          title: "Advanced hooks",
          subtitle: "configurePresetCell · makeEmptyStateConfiguration",
          make: { FKListKitAdvancedHooksExampleViewController() }
        ),
      ]
    ),
    Section(
      title: "Collection",
      rows: [
        Row(
          title: "Collection · swipe actions",
          subtitle: "FKListSwipeActionConfiguration on collection list preset",
          make: { FKListKitCollectionSwipeActionsExampleViewController() }
        ),
        Row(
          title: "Collection · skeleton preset rows",
          subtitle: "FKListSkeletonPolicy.presetRows on collection list layout",
          make: { FKListKitCollectionSkeletonPresetRowsExampleViewController() }
        ),
        Row(
          title: "Collection · list preset",
          subtitle: "FKDiffableCollectionViewController · .list layout",
          make: { FKListKitCollectionListExampleViewController() }
        ),
        Row(
          title: "Collection · delegate",
          subtitle: "FKListCollectionDelegate · refresh · pagination hooks",
          make: { FKListKitCollectionDelegateExampleViewController() }
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
        Row(
          title: "Collection · custom cell",
          subtitle: "FKListCollectionCellConfigurable · payload store",
          make: { FKListKitCollectionCustomCellExampleViewController() }
        ),
        Row(
          title: "Collection · layout hints",
          subtitle: "FKListSectionLayoutHints · compositionalLayoutProvider",
          make: { FKListKitCollectionLayoutHintsExampleViewController() }
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
