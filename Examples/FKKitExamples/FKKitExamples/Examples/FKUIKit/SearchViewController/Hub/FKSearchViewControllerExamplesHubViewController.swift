import FKUIKit
import UIKit

/// Hub for ``FKSearchViewController`` example scenarios.
final class FKSearchViewControllerExamplesHubViewController: UITableViewController {

  init() {
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private struct DemoItem {
    let title: String
    let subtitle: String
    let factory: () -> UIViewController
  }

  private struct DemoSection {
    let title: String
    let items: [DemoItem]
  }

  private lazy var sections: [DemoSection] = [
    DemoSection(title: "Placement & local filter", items: [
      DemoItem(
        title: "Local · sticky header",
        subtitle: "FKSearchMode.localFilter · FKSearchBarPlacement.stickyHeader · baseline restore",
        factory: { FKSearchViewControllerExampleLocalStickyViewController() }
      ),
      DemoItem(
        title: "Local · table header",
        subtitle: "Search bar as UITableView.tableHeaderView with frame-managed sizing",
        factory: { FKSearchViewControllerExampleLocalTableHeaderViewController() }
      ),
      DemoItem(
        title: "Bottom · keyboard aware",
        subtitle: "FKSearchBarPlacement.stickyFooter · pins above keyboardLayoutGuide",
        factory: { FKSearchViewControllerExampleBottomStickySearchViewController() }
      ),
      DemoItem(
        title: "Navigation bar placement",
        subtitle: "FKSearchBarNavigationHosting in titleView · cancel-on-focus preset",
        factory: { FKSearchViewControllerExampleNavigationBarViewController() }
      ),
    ]),
    DemoSection(title: "Remote search", items: [
      DemoItem(
        title: "Remote · loading & cancel",
        subtitle: "FKSearchResultsProviding mock API · setLoading · FKSkeleton · stale guard",
        factory: { FKSearchViewControllerExampleRemoteLoadingViewController() }
      ),
      DemoItem(
        title: "Remote · error & retry",
        subtitle: "loadFailed overlay · retryCurrentSearch() via list empty CTA",
        factory: { FKSearchViewControllerExampleErrorRetryViewController() }
      ),
      DemoItem(
        title: "Remote · idle placeholder",
        subtitle: "showsResultsOnEmptyQuery · remoteIdleSnapshot when query is empty",
        factory: { FKSearchViewControllerExampleRemoteIdlePlaceholderViewController() }
      ),
    ]),
    DemoSection(title: "States & behavior", items: [
      DemoItem(
        title: "Empty · no results",
        subtitle: "Non-empty query · zero rows · FKEmptyStateScenario.noSearchResult",
        factory: { FKSearchViewControllerExampleEmptyNoResultsViewController() }
      ),
      DemoItem(
        title: "Cancel · restore baseline",
        subtitle: "FKSearchBehaviorConfiguration.cancelRestoresBaseline = true",
        factory: { FKSearchViewControllerExampleCancelRestoresBaselineViewController() }
      ),
      DemoItem(
        title: "Cancel · keep results",
        subtitle: "cancelRestoresBaseline = false · filtered rows stay after cancel",
        factory: { FKSearchViewControllerExampleCancelKeepsResultsViewController() }
      ),
      DemoItem(
        title: "Focus on appear",
        subtitle: "FKSearchBehaviorConfiguration.focusesSearchOnAppear",
        factory: { FKSearchViewControllerExampleFocusOnAppearViewController() }
      ),
      DemoItem(
        title: "Minimum query length",
        subtitle: "minimumQueryLengthForSearchCallback = 3 · short input treated as empty",
        factory: { FKSearchViewControllerExampleMinimumQueryLengthViewController() }
      ),
    ]),
    DemoSection(title: "Presentation customization", items: [
      DemoItem(
        title: "Hot tags + history layout",
        subtitle: "Custom idle (hot tags + history) · host-handled push · FKPagingController tabbed results",
        factory: { FKSearchViewControllerExampleHotTagsHistoryLayoutViewController() }
      ),
      DemoItem(
        title: "Custom search page",
        subtitle: "FKSearchPresentationConfiguration.customIdleEmbeddedResults · makeSearchContentViewController()",
        factory: { FKSearchViewControllerExampleCustomSearchContentViewController() }
      ),
      DemoItem(
        title: "Custom results surface",
        subtitle: "FKSearchResultsDisplaying · makeResultsViewController() · remote updates",
        factory: { FKSearchViewControllerExampleCustomResultsDisplayViewController() }
      ),
      DemoItem(
        title: "Host-handled push results",
        subtitle: "resultsMode .hostHandled · onHostSearchRequested · separate results VC",
        factory: { FKSearchViewControllerExampleHostHandledPushViewController() }
      ),
    ]),
    DemoSection(title: "Subclass hooks & callbacks", items: [
      DemoItem(
        title: "ListKit · remote prefetch",
        subtitle: "Embedded FKDiffableTableViewController · FKListDelegate prefetch · see ListKit hub",
        factory: { FKListKitSearchViewControllerIntegrationExampleViewController() }
      ),
      DemoItem(
        title: "Custom list cells",
        subtitle: "makeListViewController() · register(_:forPayloadType:) · setPayload",
        factory: { FKSearchViewControllerExampleCustomListCellsViewController() }
      ),
      DemoItem(
        title: "Custom empty copy",
        subtitle: "emptyConfiguration(for:) override for empty and error phases",
        factory: { FKSearchViewControllerExampleCustomEmptyCopyViewController() }
      ),
      DemoItem(
        title: "Callbacks · state log",
        subtitle: "onPresentationStateChanged · onResultSelected · setQuery(_:)",
        factory: { FKSearchViewControllerExampleCallbacksStateLogViewController() }
      ),
      DemoItem(
        title: "Delegate · selection log",
        subtitle: "FKSearchViewControllerDelegate when callbacks are unset",
        factory: { FKSearchViewControllerExampleDelegateLogViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Search View Controller"
    navigationItem.largeTitleDisplayMode = .never
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
    sections[section].items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].items[indexPath.row]
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
    let vc = sections[indexPath.section].items[indexPath.row].factory()
    navigationController?.pushViewController(vc, animated: true)
  }
}
