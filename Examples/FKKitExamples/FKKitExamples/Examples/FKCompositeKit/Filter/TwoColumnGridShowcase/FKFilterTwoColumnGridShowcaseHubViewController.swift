import UIKit

final class FKFilterTwoColumnGridShowcaseHubViewController: UITableViewController {

  private static let sectionSpec: [(title: String, scenarios: [FKFilterTwoColumnGridShowcaseScenario])] = [
    (
      "Baseline",
      [.baselineDefaults]
    ),
    (
      "Section headers",
      [
        .sectionCollapsePlain,
        .sectionCollapseInsetGroupedChrome,
        .collapseChevronHidden,
        .headerSelectionWithoutCollapse,
      ]
    ),
    (
      "Selection",
      [
        .globalSingleAcrossSections,
        .withinSectionSingle,
        .multipleSelectionTabAndSections,
      ]
    ),
    (
      "Customization",
      [
        .customLeftAndItemCells,
        .narrowLeftColumn,
        .singleColumnDense,
        .fourColumnsWide,
        .disabledPillItem,
      ]
    ),
    (
      "Height",
      [
        .heightBehaviorFixed,
        .heightBehaviorCapped,
      ]
    ),
    (
      "Callbacks",
      [.onChangeOnlyNoSelection]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Two-column grid showcase"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    tableView.estimatedRowHeight = 88
    tableView.rowHeight = UITableView.automaticDimension
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    Self.sectionSpec.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    Self.sectionSpec[section].scenarios.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    Self.sectionSpec[section].title
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let scenario = Self.sectionSpec[indexPath.section].scenarios[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = UIListContentConfiguration.subtitleCell()
    config.text = scenario.menuTitle
    config.secondaryText = scenario.menuSubtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let scenario = Self.sectionSpec[indexPath.section].scenarios[indexPath.row]
    navigationController?.pushViewController(
      FKFilterTwoColumnGridShowcaseDetailViewController(scenario: scenario),
      animated: true
    )
  }
}
