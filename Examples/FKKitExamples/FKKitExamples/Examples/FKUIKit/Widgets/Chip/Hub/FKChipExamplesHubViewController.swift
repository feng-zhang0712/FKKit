import FKUIKit
import UIKit

/// Grouped index for ``FKChip``, ``FKTag``, and ``FKChipGroup`` demos.
final class FKChipExamplesHubViewController: UITableViewController {

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
    DemoSection(title: "FKChip · Modes", items: [
      DemoItem(
        title: "Filter & choice",
        subtitle: "Standalone chips — filter/choice modes, icons, border-selected style, disabled state.",
        factory: { FKChipExampleFilterChoiceViewController() }
      ),
      DemoItem(
        title: "Input tokens",
        subtitle: "Input mode with removable ✕, 44 pt remove hit area, VoiceOver custom action.",
        factory: { FKChipExampleInputTokensViewController() }
      ),
      DemoItem(
        title: "Suggestion one-shot",
        subtitle: "Suggestion mode emits primaryActionTriggered without persistent selection.",
        factory: { FKChipExampleSuggestionViewController() }
      ),
      DemoItem(
        title: "Configuration playground",
        subtitle: "Live toggles for size, corner style, selected border, haptics, highlight scale.",
        factory: { FKChipExamplePlaygroundViewController() }
      ),
    ]),
    DemoSection(title: "FKTag", items: [
      DemoItem(
        title: "All variants",
        subtitle: "Neutral, brand, success, warning, error, outline, and custom colors.",
        factory: { FKTagExampleVariantsViewController() }
      ),
      DemoItem(
        title: "Sizes & truncation",
        subtitle: "XS/S/M presets, leading icon, maxWidth with truncating tail.",
        factory: { FKTagExampleSizesViewController() }
      ),
    ]),
    DemoSection(title: "FKChipGroup", items: [
      DemoItem(
        title: "Single selection bar",
        subtitle: "Filter bar with .single mode, setSelectedIDs, onSelectionChange.",
        factory: { FKChipGroupExampleSingleViewController() }
      ),
      DemoItem(
        title: "Multiple with limit",
        subtitle: "multiple(max:), overflowBehavior notify, onSelectionLimitReached.",
        factory: { FKChipGroupExampleMultipleLimitViewController() }
      ),
      DemoItem(
        title: "Horizontal scroll",
        subtitle: "horizontalScroll layout for dense filter rails.",
        factory: { FKChipGroupExampleHorizontalScrollViewController() }
      ),
      DemoItem(
        title: "Flow wrap & Dynamic Type",
        subtitle: "flow(wrap:), constrained width, content-size category relayout.",
        factory: { FKChipGroupExampleFlowWrapViewController() }
      ),
    ]),
    DemoSection(title: "Integration", items: [
      DemoItem(
        title: "List row trailing tag",
        subtitle: "UITableView cell with FKTag as metadata capsule on the trailing edge.",
        factory: { FKChipExampleListRowTagViewController() }
      ),
      DemoItem(
        title: "SwiftUI bridges",
        subtitle: "FKChipRepresentable, FKChipGroupRepresentable, FKTagView.",
        factory: { FKChipExampleSwiftUIViewController() }
      ),
      DemoItem(
        title: "RTL & appearance",
        subtitle: "Forced RTL layout, light/dark interface styles on chips and tags.",
        factory: { FKChipExampleEnvironmentViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Chip"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
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
    navigationController?.pushViewController(sections[indexPath.section].items[indexPath.row].factory(), animated: true)
  }
}
