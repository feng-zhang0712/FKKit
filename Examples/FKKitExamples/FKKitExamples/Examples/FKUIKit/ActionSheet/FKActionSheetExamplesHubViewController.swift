import UIKit

/// Index of ``FKActionSheet`` examples, grouped by integration path.
final class FKActionSheetExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private struct Section {
    let title: String
    let rows: [Row]
  }

  private let sections: [Section] = [
    Section(
      title: "Getting started",
      rows: [
        Row(
          title: "Basics",
          subtitle: "init, present, validate, retain instance",
          make: { FKActionSheetExampleBasicsViewController() }
        ),
        Row(
          title: "Presentation",
          subtitle: "Bottom sheet, popover anchors, window scene, panel height",
          make: { FKActionSheetExamplePresentationViewController() }
        ),
        Row(
          title: "Centered card",
          subtitle: "Floating card, backdrop, presets, scroll, destructive flows",
          make: { FKActionSheetExampleCenteredViewController() }
        ),
      ]
    ),
    Section(
      title: "Rows & appearance",
      rows: [
        Row(
          title: "Appearance & layout",
          subtitle: "Presets, leading alignment, separators, section titles",
          make: { FKActionSheetExampleAppearanceViewController() }
        ),
        Row(
          title: "Symbols & row states",
          subtitle: "Symbols, disabled/loading, stay-open, toggle rows",
          make: { FKActionSheetExampleSymbolsAndStatesViewController() }
        ),
        Row(
          title: "Custom header & rows",
          subtitle: "Custom views, metadata, non-selectable banner row",
          make: { FKActionSheetExampleCustomContentViewController() }
        ),
      ]
    ),
    Section(
      title: "Selection & behavior",
      rows: [
        Row(
          title: "Long list & scroll",
          subtitle: "Tall lists, selection memory, scroll-to-selection, indicator styles",
          make: { FKActionSheetExampleLongListViewController() }
        ),
        Row(
          title: "Single & multiple selection",
          subtitle: "Scopes, max count, validation, keepsSheetPresentedOnSelection",
          make: { FKActionSheetExampleSelectionViewController() }
        ),
        Row(
          title: "Handlers & lifecycle",
          subtitle: "Handler timing, haptics, hooks, dismiss reasons",
          make: { FKActionSheetExampleHandlersViewController() }
        ),
        Row(
          title: "Live updates",
          subtitle: "reload, updateAction, dismiss, alreadyPresented guard",
          make: { FKActionSheetExampleLiveUpdatesViewController() }
        ),
        Row(
          title: "Loading content",
          subtitle: "Deferred rows, finishLoading, setLoading retry, cancel while loading",
          make: { FKActionSheetExampleLoadingContentViewController() }
        ),
      ]
    ),
    Section(
      title: "Integration",
      rows: [
        Row(
          title: "Builder & alert migration",
          subtitle: "FKActionSheetBuilder and UIAlertAction-style configuration",
          make: { FKActionSheetExampleBuilderViewController() }
        ),
        Row(
          title: "SwiftUI bridge",
          subtitle: "View.fkActionSheet, popover anchors, loading via configuration binding",
          make: { FKActionSheetExampleSwiftUIViewController() }
        ),
      ]
    ),
  ]

  convenience init() {
    self.init(style: .insetGrouped)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKActionSheet"
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
    sections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = sections[indexPath.section].rows[indexPath.row]
    var config = cell.defaultContentConfiguration()
    config.text = row.title
    config.secondaryText = row.subtitle
    config.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = config
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    let row = sections[indexPath.section].rows[indexPath.row]
    navigationController?.pushViewController(row.make(), animated: true)
  }
}
