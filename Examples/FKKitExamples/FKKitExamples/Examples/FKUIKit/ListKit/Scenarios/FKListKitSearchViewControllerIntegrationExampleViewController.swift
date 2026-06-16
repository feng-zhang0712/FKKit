import FKUIKit
import UIKit

/// Recommended ListKit search path: ``FKSearchViewController`` orchestrates remote queries,
/// embedded ``FKDiffableTableViewController``, and ``FKListDelegate`` prefetch hooks.
final class FKListKitSearchViewControllerIntegrationExampleViewController: FKSearchViewController {
  private static let leadingPrefetchTargetSize = CGSize(width: 28, height: 28)

  private var statusLabel: UILabel!

  init() {
    var config = FKSearchViewControllerDefaults.remote(placement: .stickyHeader)
    config.list.prefetch.isEnabled = true
    config.behavior.animatesSnapshotChanges = false
    super.init(configuration: config, placeholder: "Search catalog (ListKit + Search)")
    resultsProvider = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SearchViewController · ListKit"
    if let tableView = listViewController?.tableView {
      statusLabel = FKListKitExampleStatusStrip.install(on: self, above: tableView)
    }
    callbacks.onResultSelected = { [weak self] itemID in
      FKListKitExampleStatusStrip.append("selected \(itemID.rawValue)", to: self?.statusLabel)
    }
  }
}

extension FKListKitSearchViewControllerIntegrationExampleViewController: FKSearchResultsProviding {
  func search(query: String) async throws -> FKSearchResultsResponse {
    let nanos: UInt64 = 800_000_000
    try await Task.sleep(nanoseconds: nanos)
    try Task.checkCancellation()

    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      return FKSearchResultsResponse(snapshot: FKListSnapshot())
    }

    let photoIDs = [10, 11, 12, 16, 17, 20, 21, 22, 23, 24]
    let items = FKSearchViewControllerExampleSupport.catalogItems.enumerated().compactMap { index, title -> FKListItem? in
      guard title.localizedCaseInsensitiveContains(trimmed) else { return nil }
      let photoID = photoIDs[index % photoIDs.count]
      return FKListItem(
        id: FKListItemID("search-icon-\(index)"),
        kind: .preset(.icon(FKListIconRow(
          leading: .remoteURL(FKListKitExampleIcons.remoteURL(id: photoID)),
          title: title,
          subtitle: "FKSearchViewController · FKListImagePrefetchHelper"
        )))
      )
    }
    return FKSearchResultsResponse(snapshot: FKListSnapshot(items: items))
  }
}

extension FKListKitSearchViewControllerIntegrationExampleViewController {
  func list(_ list: FKDiffableTableViewController, prefetchItems ids: [FKListItemID]) {
    FKListImagePrefetchHelper.prefetchLeadingIcons(
      ids: ids,
      in: list.currentSnapshot,
      targetSize: Self.leadingPrefetchTargetSize
    )
    FKListKitExampleStatusStrip.append(
      "prefetch \(ids.count) via FKListImagePrefetchHelper",
      to: statusLabel
    )
  }

  func list(_ list: FKDiffableTableViewController, cancelPrefetching ids: [FKListItemID]) {
    FKListImagePrefetchHelper.cancelPrefetchLeadingIcons(
      ids: ids,
      in: list.currentSnapshot,
      targetSize: Self.leadingPrefetchTargetSize
    )
    FKListKitExampleStatusStrip.append("cancel prefetch \(ids.count)", to: statusLabel)
  }
}
