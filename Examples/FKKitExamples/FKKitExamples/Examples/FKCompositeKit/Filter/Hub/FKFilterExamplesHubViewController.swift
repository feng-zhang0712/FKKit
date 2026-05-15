import UIKit

/// Table entry list for Filter panel showcases and dropdown demos.
final class FKFilterExamplesHubViewController: UITableViewController {

  private enum Row: Int, CaseIterable {
    case dropdownFilterDemos
    case twoColumnListShowcase
    case twoColumnGridShowcase
    case chipsPanelShowcase
    case singleListPanelShowcase

    var title: String {
      switch self {
      case .dropdownFilterDemos:
        return "Dropdown filter demos"
      case .twoColumnListShowcase:
        return "Two-column list showcase"
      case .twoColumnGridShowcase:
        return "Two-column grid showcase"
      case .chipsPanelShowcase:
        return "Chips panel showcase"
      case .singleListPanelShowcase:
        return "Single-list panel showcase"
      }
    }

    var subtitle: String {
      switch self {
      case .dropdownFilterDemos:
        return "Anchored dropdown patterns: tab layout, transitions, backdrop, and panel caching."
      case .twoColumnListShowcase:
        return "Isolated FKFilterTwoColumnListViewController scenarios."
      case .twoColumnGridShowcase:
        return "Isolated FKFilterTwoColumnGridViewController scenarios."
      case .chipsPanelShowcase:
        return "Isolated FKFilterChipsViewController scenarios."
      case .singleListPanelShowcase:
        return "Isolated FKFilterSingleListViewController scenarios."
      }
    }

    func makeViewController() -> UIViewController {
      switch self {
      case .dropdownFilterDemos:
        return FKFilterDropdownDemosHubViewController()
      case .twoColumnListShowcase:
        return FKFilterTwoColumnListShowcaseHubViewController()
      case .twoColumnGridShowcase:
        return FKFilterTwoColumnGridShowcaseHubViewController()
      case .chipsPanelShowcase:
        return FKFilterChipsPanelShowcaseHubViewController()
      case .singleListPanelShowcase:
        return FKFilterSingleListPanelShowcaseHubViewController()
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
