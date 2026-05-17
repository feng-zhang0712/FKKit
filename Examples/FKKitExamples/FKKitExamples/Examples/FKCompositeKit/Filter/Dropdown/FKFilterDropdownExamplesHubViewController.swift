import UIKit

/// Anchored-dropdown filter patterns: tab strip layout, tab-switch transitions, backdrop, and content caching.
final class FKFilterDropdownExamplesHubViewController: UITableViewController {

  private static let sectionSpec: [(title: String, examples: [FKFilterDropdownAnchoredExample])] = [
    (
      "Tab strip & panel mix",
      [.scrollableSixPanels]
    ),
    (
      "Equal-width tabs",
      [.equalCommerce, .equalLibrary, .compactCrossfadeBaseline]
    ),
    (
      "Tab switching",
      [.switchDismissThenPresent, .switchSlideVertical]
    ),
    (
      "Backdrop",
      [.backdropStrongDim, .backdropPassthrough]
    ),
    (
      "Caching & layout animation",
      [.contentRecreate, .layoutAnimationSlow]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dropdown filter examples"
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
    let example = Self.sectionSpec[indexPath.section].examples[indexPath.row]
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = UIListContentConfiguration.subtitleCell()
    config.text = example.menuTitle
    config.secondaryText = example.menuSubtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let example = Self.sectionSpec[indexPath.section].examples[indexPath.row]
    navigationController?.pushViewController(
      FKFilterDropdownAnchoredExampleViewController(anchoredExample: example),
      animated: true
    )
  }
}
