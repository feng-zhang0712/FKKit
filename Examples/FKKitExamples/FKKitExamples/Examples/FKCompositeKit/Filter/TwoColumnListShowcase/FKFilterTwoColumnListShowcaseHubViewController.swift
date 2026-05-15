import UIKit

/// Entry table for every ``FKFilterTwoColumnListShowcaseScenario`` (self-contained, no shared Filter demo state).
final class FKFilterTwoColumnListShowcaseHubViewController: UITableViewController {

  private static let sectionSpec: [(title: String, scenarios: [FKFilterTwoColumnListShowcaseScenario])] = [
    (
      "Baseline & table style",
      [
        .baselinePlainDefaults,
        .plainStyleExplicit,
        .insetGroupedFullGroupedConfiguration,
        .groupedFootersOnly,
        .customChromeAndListCellStyles,
      ]
    ),
    (
      "Selection",
      [
        .globalSingleAcrossSections,
        .withinSectionSingleTwoSections,
        .multipleSelectionTabAndSections,
        .sectionMultipleTabSingleEffectiveSingle,
      ]
    ),
    (
      "Section headers",
      [
        .sectionsWithoutVisibleHeaders,
        .systemTitledSectionHeaders,
        .selectableSectionHeadersPreset,
        .selectableHeadersCustomStyle,
        .sectionCollapsePlainDefaults,
        .sectionCollapseInsetGroupedMixedInitial,
        .sectionCollapseChevronHidden,
      ]
    ),
    (
      "Rows & hooks",
      [
        .disabledRowAndAttributedText,
        .customLeftAndRightCellHooks,
        .narrowCategoryColumnRatio,
        .wideRightSeparatorInsets,
      ]
    ),
    (
      "Height behavior",
      [
        .heightBehaviorFixed,
        .heightBehaviorCapped,
        .heightBehaviorScreenFraction,
        .heightBehaviorAutomaticTallFloor,
      ]
    ),
    (
      "Lifecycle & edge cases",
      [
        .emptyCategorySyntheticSelection,
        .onChangeOnlyWithoutSelectionHandler,
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Two-column list showcase"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    tableView.estimatedRowHeight = 96
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
    let detail = FKFilterTwoColumnListShowcaseDetailViewController(scenario: scenario)
    navigationController?.pushViewController(detail, animated: true)
  }
}
