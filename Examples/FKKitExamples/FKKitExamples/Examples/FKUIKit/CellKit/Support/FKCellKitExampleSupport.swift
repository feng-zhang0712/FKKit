import FKUIKit
import UIKit

/// Hub row describing a nested CellKit example screen.
@MainActor
struct FKCellKitExampleHubItem {
  let title: String
  let subtitle: String
  let factory: () -> UIViewController
}

/// Grouped hub section for CellKit example navigation.
@MainActor
struct FKCellKitExampleHubSection {
  let title: String
  let items: [FKCellKitExampleHubItem]
}

/// Base table controller for CellKit demo screens driven by ``FKCellKitExampleSection`` models.
@MainActor
class FKCellKitExampleTableViewController: UITableViewController {
  let demoSections: [FKCellKitExampleSection]
  let usesInsetGroupedStyle: Bool
  private let callbacks = FKCellKitExampleCallbacks()
  private var registered = false

  init(title: String, sections: [FKCellKitExampleSection], style: UITableView.Style = .insetGrouped) {
    self.demoSections = sections
    self.usesInsetGroupedStyle = style == .insetGrouped
    super.init(style: style)
    self.title = title
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.largeTitleDisplayMode = .never
    tableView.fk_registerCellKitStructureViews()
    tableView.fk_registerFormSectionHeaderView()
    registerRowsIfNeeded()
    wireCallbacks()
  }

  private func registerRowsIfNeeded() {
    guard !registered else { return }
    registered = true
    for section in demoSections {
      for row in section.rows {
        row.register(tableView)
      }
    }
  }

  private func wireCallbacks() {
    callbacks.onToast = { [weak self] message in
      FKToast.show(message)
      _ = self
    }
    callbacks.onSwitchChanged = { [weak self] id, isOn in
      FKToast.show("\(id): \(isOn ? "On" : "Off")")
      _ = self
    }
    callbacks.onLinkTapped = { [weak self] link in
      FKToast.show("Link: \(link)")
      _ = self
    }
    callbacks.onSelectionChanged = { [weak self] value in
      FKToast.show("Selected: \(value)")
      _ = self
    }
    callbacks.onAction = { [weak self] action in
      FKToast.show(action)
      _ = self
    }
  }

  override func numberOfSections(in tableView: UITableView) -> Int {
    demoSections.count
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    demoSections[section].rows.count
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    demoSections[section].headerConfiguration == nil ? demoSections[section].title : nil
  }

  override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    demoSections[section].footerConfiguration == nil ? demoSections[section].footer : nil
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let header = demoSections[section].headerConfiguration else { return nil }
    let view = tableView.fk_dequeueCellKitSectionHeader(for: section)
    view.apply(header)
    return view
  }

  override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    guard let footer = demoSections[section].footerConfiguration else { return nil }
    let view = tableView.dequeueReusableHeaderFooterView(
      withIdentifier: FKCellSectionFooterView.reuseIdentifier
    ) as! FKCellSectionFooterView
    view.apply(footer)
    view.onLinkTapped = { [weak self] link in
      FKToast.show("Footer link tapped")
      _ = self
    }
    return view
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    demoSections[indexPath.section].rows[indexPath.row].dequeue(tableView, indexPath)
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

/// Reusable hub list for nested CellKit example entry points.
@MainActor
class FKCellKitExamplesListViewController: UITableViewController {
  private let screenTitle: String
  private let sections: [FKCellKitExampleHubSection]

  init(title: String, sections: [FKCellKitExampleHubSection]) {
    self.screenTitle = title
    self.sections = sections
    super.init(style: .insetGrouped)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = screenTitle
    navigationItem.largeTitleDisplayMode = .never
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
