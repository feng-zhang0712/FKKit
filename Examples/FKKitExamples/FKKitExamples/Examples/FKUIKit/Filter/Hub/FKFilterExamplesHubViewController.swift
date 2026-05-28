import UIKit

/// Table entry list for Filter panel and anchored-dropdown examples.
final class FKFilterExamplesHubViewController: UITableViewController {

  private enum Row: Int, CaseIterable {
    case dropdownFilterExamples
    case twoColumnListExamples
    case twoColumnGridExamples
    case chipsPanelExamples
    case singleListPanelExamples

    var title: String {
      switch self {
      case .dropdownFilterExamples:
        return "Dropdown filter examples"
      case .twoColumnListExamples:
        return "Two-column list examples"
      case .twoColumnGridExamples:
        return "Two-column grid examples"
      case .chipsPanelExamples:
        return "Chips panel examples"
      case .singleListPanelExamples:
        return "Single-list panel examples"
      }
    }

    var subtitle: String {
      switch self {
      case .dropdownFilterExamples:
        return "Anchored dropdown patterns: tab layout, transitions, backdrop, and panel caching."
      case .twoColumnListExamples:
        return "Isolated FKFilterTwoColumnListViewController configurations."
      case .twoColumnGridExamples:
        return "Isolated FKFilterTwoColumnGridViewController configurations."
      case .chipsPanelExamples:
        return "Isolated FKFilterChipsViewController configurations."
      case .singleListPanelExamples:
        return "Isolated FKFilterSingleListViewController configurations."
      }
    }

    func makeViewController() -> UIViewController {
      switch self {
      case .dropdownFilterExamples:
        return FKFilterDropdownExamplesHubViewController()
      case .twoColumnListExamples:
        return FKFilterTwoColumnListExampleHubViewController()
      case .twoColumnGridExamples:
        return FKFilterTwoColumnGridExampleHubViewController()
      case .chipsPanelExamples:
        return FKFilterChipsPanelExampleHubViewController()
      case .singleListPanelExamples:
        return FKFilterSingleListPanelExampleHubViewController()
      }
    }
  }

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Filter"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    tableView.rowHeight = 76
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    Row.allCases.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let row = Row.allCases[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = UIListContentConfiguration.subtitleCell()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let vc = Row.allCases[indexPath.row].makeViewController()
    navigationController?.pushViewController(vc, animated: true)
  }
}
