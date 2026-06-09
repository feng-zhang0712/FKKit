import FKUIKit
import UIKit

/// Hub for ``FKSearchBar`` and ``FKSearchField`` example scenarios.
final class FKSearchExamplesHubViewController: UITableViewController {

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
    DemoSection(title: "FKSearchBar", items: [
      DemoItem(
        title: "Debounced filter",
        subtitle: "Raw textChanged vs debounced searchQueryChanged with interval control.",
        factory: { FKSearchExampleDebouncedFilterViewController() }
      ),
      DemoItem(
        title: "Submit on Return",
        subtitle: "Return `.search`, empty submit policy, resign-on-submit.",
        factory: { FKSearchExampleSubmitOnReturnViewController() }
      ),
      DemoItem(
        title: "Navigation bar",
        subtitle: "FKSearchBarNavigationHosting in titleView with cancel-on-focus.",
        factory: { FKSearchExampleNavigationBarViewController() }
      ),
      DemoItem(
        title: "Inline card",
        subtitle: "`.inlineCard` preset — capsule bar above a filtered table.",
        factory: { FKSearchExampleInlineCardViewController() }
      ),
      DemoItem(
        title: "Loading search",
        subtitle: "setLoading during mock async work; spinner vs disabled input.",
        factory: { FKSearchExampleLoadingSearchViewController() }
      ),
    ]),
    DemoSection(title: "FKSearchField", items: [
      DemoItem(
        title: "Compact filter",
        subtitle: "Embedded field without cancel — clear resets query.",
        factory: { FKSearchExampleSearchFieldCompactViewController() }
      ),
    ]),
    DemoSection(title: "Behavior & configuration", items: [
      DemoItem(
        title: "Cancel policies",
        subtitle: "clearAndResign, resignOnly, revertAndResign.",
        factory: { FKSearchExampleCancelPoliciesViewController() }
      ),
      DemoItem(
        title: "Playground",
        subtitle: "Layout styles, debounce toggle, clear visibility, blur, setText, textField accessory.",
        factory: { FKSearchExamplePlaygroundViewController() }
      ),
      DemoItem(
        title: "Delegate log",
        subtitle: "FKSearchBarDelegate when callbacks are unset.",
        factory: { FKSearchExampleDelegateLogViewController() }
      ),
    ]),
    DemoSection(title: "Integration & environment", items: [
      DemoItem(
        title: "Table + empty state",
        subtitle: "Debounced UITableView filter with `.noSearchResult` overlay.",
        factory: { FKSearchExampleTableFilterEmptyViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "FKSearchBarRepresentable and FKSearchFieldRepresentable bindings.",
        factory: { FKSearchExampleSwiftUIViewController() }
      ),
      DemoItem(
        title: "Dark / Dynamic Type / RTL",
        subtitle: "Interface style, scaled typography, semantic layout direction.",
        factory: { FKSearchExampleEnvironmentViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Search"
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
