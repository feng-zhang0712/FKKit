import UIKit

final class FKFilterTwoColumnGridExampleHubViewController: UITableViewController {

  private static let sectionSpec: [(title: String, examples: [FKFilterTwoColumnGridExampleCase])] = [
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
    title = "Two-column grid examples"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    tableView.estimatedRowHeight = 88
    tableView.rowHeight = UITableView.automaticDimension
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    Self.sectionSpec.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    Self.sectionSpec[section].examples.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    Self.sectionSpec[section].title
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let exampleCase = Self.sectionSpec[indexPath.section].examples[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = UIListContentConfiguration.subtitleCell()
    config.text = exampleCase.menuTitle
    config.secondaryText = exampleCase.menuSubtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let exampleCase = Self.sectionSpec[indexPath.section].examples[indexPath.row]
    navigationController?.pushViewController(
      FKFilterTwoColumnGridExampleDetailViewController(exampleCase: exampleCase),
      animated: true
    )
  }
}
