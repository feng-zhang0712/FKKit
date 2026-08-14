import UIKit

/// Entry hub for ``FKCheckbox``, ``FKRadioButton``, ``FKRadioGroup``, and ``FKSelectionListChrome`` demos.
final class FKSelectionControlExamplesHubViewController: UITableViewController {

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
    DemoSection(title: "Checkbox", items: [
      DemoItem(
        title: "States",
        subtitle: "Default, checked, indeterminate, disabled, disabled+on.",
        factory: { FKCheckboxExampleStatesViewController() }
      ),
      DemoItem(
        title: "Sizes",
        subtitle: "Small 16 / medium 22 / large 28 indicators.",
        factory: { FKCheckboxExampleSizesViewController() }
      ),
      DemoItem(
        title: "Tints",
        subtitle: "Blue, green, red, orange, purple presets.",
        factory: { FKCheckboxExampleTintsViewController() }
      ),
      DemoItem(
        title: "List + chrome",
        subtitle: "IN LIST card with FKSelectionListChrome separators.",
        factory: { FKCheckboxExampleListViewController() }
      ),
      DemoItem(
        title: "Indicator only",
        subtitle: "Compact control for custom table cells.",
        factory: { FKCheckboxExampleIndicatorOnlyViewController() }
      ),
      DemoItem(
        title: "Indeterminate tap",
        subtitle: "promoteToChecked vs cycle behaviors.",
        factory: { FKCheckboxExampleIndeterminateTapViewController() }
      ),
      DemoItem(
        title: "Programmatic",
        subtitle: "setCheckState and toggle from buttons.",
        factory: { FKCheckboxExampleProgrammaticViewController() }
      ),
      DemoItem(
        title: "Error state",
        subtitle: "showsError validation styling.",
        factory: { FKCheckboxExampleErrorViewController() }
      ),
      DemoItem(
        title: "Agreement",
        subtitle: "Attributed title links, required marker, agreement preset.",
        factory: { FKCheckboxExampleAgreementViewController() }
      ),
      DemoItem(
        title: "Select all",
        subtitle: "Parent aggregate from child checked flags.",
        factory: { FKCheckboxExampleSelectAllViewController() }
      ),
      DemoItem(
        title: "Read-only",
        subtitle: "Renders state; ignores toggle taps.",
        factory: { FKCheckboxExampleReadOnlyViewController() }
      ),
      DemoItem(
        title: "Trailing indicator",
        subtitle: "Settings-style trailing indicator edge.",
        factory: { FKCheckboxExampleTrailingIndicatorViewController() }
      ),
      DemoItem(
        title: "Custom glyphs",
        subtitle: "Custom checkmark and indeterminate images.",
        factory: { FKCheckboxExampleCustomGlyphViewController() }
      ),
    ]),
    DemoSection(title: "Radio button", items: [
      DemoItem(
        title: "Button states",
        subtitle: "Default, selected, disabled, disabled+on.",
        factory: { FKRadioButtonExampleStatesViewController() }
      ),
      DemoItem(
        title: "Sizes & tints",
        subtitle: "SM/MD/LG and five tint presets.",
        factory: { FKRadioButtonExampleAppearanceViewController() }
      ),
      DemoItem(
        title: "Trailing indicator",
        subtitle: "Radio row with trailing indicator edge.",
        factory: { FKRadioButtonExampleTrailingIndicatorViewController() }
      ),
    ]),
    DemoSection(title: "Radio group", items: [
      DemoItem(
        title: "Inset grouped",
        subtitle: "Billing period card list (design default).",
        factory: { FKRadioGroupExampleInsetGroupedViewController() }
      ),
      DemoItem(
        title: "Plain & horizontal",
        subtitle: "Plain stack and horizontal scrolling styles.",
        factory: { FKRadioGroupExampleLayoutStylesViewController() }
      ),
      DemoItem(
        title: "Disabled option",
        subtitle: "One option disabled; selected Disabled+On.",
        factory: { FKRadioGroupExampleDisabledOptionViewController() }
      ),
      DemoItem(
        title: "Allows deselection",
        subtitle: "Tap selected row again to clear (empty allowed).",
        factory: { FKRadioGroupExampleDeselectionViewController() }
      ),
      DemoItem(
        title: "Option images",
        subtitle: "Leading icons between indicator and title.",
        factory: { FKRadioGroupExampleImagesViewController() }
      ),
      DemoItem(
        title: "Subtitles",
        subtitle: "Title + footnote rows inside the group.",
        factory: { FKRadioGroupExampleSubtitleViewController() }
      ),
      DemoItem(
        title: "Error state",
        subtitle: "Card border error until a choice is made.",
        factory: { FKRadioGroupExampleErrorViewController() }
      ),
      DemoItem(
        title: "Header & footer",
        subtitle: "Titles outside the inset grouped card.",
        factory: { FKRadioGroupExampleHeaderFooterViewController() }
      ),
    ]),
    DemoSection(title: "Integration", items: [
      DemoItem(
        title: "SwiftUI bridge",
        subtitle: "FKCheckbox / RadioButton / RadioGroup representables.",
        factory: { FKSelectionExampleSwiftUIViewController() }
      ),
    ]),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SelectionControl"
    navigationItem.largeTitleDisplayMode = .never
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { sections.count }

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
