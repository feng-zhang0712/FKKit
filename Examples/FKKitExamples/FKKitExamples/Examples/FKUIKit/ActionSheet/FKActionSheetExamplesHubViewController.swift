import UIKit

final class FKActionSheetExamplesHubViewController: UITableViewController {
  private struct Row {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [Row] = [
    Row(
      title: "Basics",
      subtitle: "Instance init + present, static convenience, validate",
      make: { FKActionSheetExampleBasicsViewController() }
    ),
    Row(
      title: "Many Actions",
      subtitle: "Long list, maximumPanelHeight, selection memory & indicator styles",
      make: { FKActionSheetExampleManyActionsViewController() }
    ),
    Row(
      title: "Appearance & Layout",
      subtitle: "Presets, leading alignment, separators, section titles",
      make: { FKActionSheetExampleAppearanceViewController() }
    ),
    Row(
      title: "Symbols & Row States",
      subtitle: "SF Symbols, subtitles, disabled, loading, stay-open rows",
      make: { FKActionSheetExampleSymbolsAndStatesViewController() }
    ),
    Row(
      title: "Single Selection",
      subtitle: "selectedActionID restore, check, radio, and highlight styles",
      make: { FKActionSheetExampleSelectionViewController() }
    ),
    Row(
      title: "Custom Header & Rows",
      subtitle: "Custom views, metadata, non-selectable banner row",
      make: { FKActionSheetExampleCustomContentViewController() }
    ),
    Row(
      title: "Toggle Rows",
      subtitle: "Switch rows that keep the sheet presented",
      make: { FKActionSheetExampleToggleViewController() }
    ),
    Row(
      title: "Handlers & Lifecycle",
      subtitle: "Handler timing, actionHandler, haptics, delegate, dismiss reasons",
      make: { FKActionSheetExampleHandlersViewController() }
    ),
    Row(
      title: "Live Updates",
      subtitle: "Retained sheet reload/updateAction/dismiss, presentOnce, isPresenting",
      make: { FKActionSheetExampleLiveUpdatesViewController() }
    ),
    Row(
      title: "Presentation",
      subtitle: "Bottom, centered, popover, window scene, backdrop dismiss",
      make: { FKActionSheetExamplePresentationViewController() }
    ),
    Row(
      title: "Builder & Alert Migration",
      subtitle: "FKActionSheetBuilder and UIAlertAction-style configuration",
      make: { FKActionSheetExampleBuilderViewController() }
    ),
    Row(
      title: "SwiftUI Bridge",
      subtitle: "View.fkActionSheet, onDismiss, popoverSourceView anchor",
      make: { FKActionSheetExampleSwiftUIViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKActionSheet"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = rows[indexPath.row]
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
    navigationController?.pushViewController(rows[indexPath.row].make(), animated: true)
  }
}
