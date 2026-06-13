import FKUIKit
import UIKit

/// Demonstrates selection modes, programmatic selection, delegate callbacks, and preserved selection across updates.
final class FKListKitSelectionModesExampleViewController: FKDiffableTableViewController, FKListDelegate {
  private var modeControl: UISegmentedControl?
  private var selectionStatusLabel: UILabel?
  private var didInstallModeHeader = false

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.selection.preservesSelectionOnUpdates = true
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config)
    delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Selection Modes"
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "Select 1st", style: .plain, target: self, action: #selector(selectFirstRow)),
      UIBarButtonItem(title: "Deselect 1st", style: .plain, target: self, action: #selector(deselectFirstRow)),
      UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(reloadSnapshot)),
    ]
    applySnapshot(buildSnapshot(), animatingDifferences: false)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard tableView.bounds.width > 0 else { return }
    if !didInstallModeHeader {
      didInstallModeHeader = true
      installModeHeader()
    } else {
      FKListKitExampleTableHeader.refreshIfWidthChanged(tableView)
    }
  }

  private func updateSelectionStatus(_ text: String) {
    selectionStatusLabel?.text = text
    FKListKitExampleTableHeader.refresh(tableView)
  }

  private func installModeHeader() {
    let control = UISegmentedControl(items: ["Single", "Single·2nd tap", "Multiple", "None"])
    control.selectedSegmentIndex = 0
    control.translatesAutoresizingMaskIntoConstraints = false
    control.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
    modeControl = control

    let statusLabel = UILabel()
    statusLabel.font = .preferredFont(forTextStyle: .footnote)
    statusLabel.textColor = .secondaryLabel
    statusLabel.numberOfLines = 0
    statusLabel.text = "Tap a row to select"
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    selectionStatusLabel = statusLabel

    let container = UIView()
    container.backgroundColor = .systemBackground
    container.addSubview(control)
    container.addSubview(statusLabel)
    NSLayoutConstraint.activate([
      control.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
      control.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      control.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
      statusLabel.topAnchor.constraint(equalTo: control.bottomAnchor, constant: 8),
      statusLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      statusLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
      statusLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
    ])

    FKListKitExampleTableHeader.apply(container, to: tableView)
  }

  @objc private func modeChanged() {
    guard let control = modeControl else { return }
    switch control.selectedSegmentIndex {
    case 0:
      configuration.selection.mode = .single(deselectOnSecondTap: false)
    case 1:
      configuration.selection.mode = .single(deselectOnSecondTap: true)
    case 2:
      configuration.selection.mode = .multiple
    default:
      configuration.selection.mode = .none
    }
    applySelectionConfiguration()
    if case .none = configuration.selection.mode {
      tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: false) }
      updateSelectionStatus("Selection disabled")
    }
  }

  @objc private func selectFirstRow() {
    selectItem(withID: FKListItemID("row-1"), animated: true, scrollPosition: .middle)
  }

  @objc private func deselectFirstRow() {
    deselectItem(withID: FKListItemID("row-1"), animated: true)
  }

  @objc private func reloadSnapshot() {
    applySnapshot(buildSnapshot(), animatingDifferences: true)
  }

  private func buildSnapshot() -> FKListSnapshot {
    let items = (1 ... 8).map { index in
      FKListItem.text(id: FKListItemID("row-\(index)"), title: "Selectable row \(index)")
    }
    return FKListSnapshot(items: items)
  }
}

extension FKListKitSelectionModesExampleViewController {
  func list(_ list: FKDiffableTableViewController, didSelect item: FKListItemID) {
    updateSelectionStatus("Delegate didSelect: \(item.rawValue)")
  }

  func list(_ list: FKDiffableTableViewController, didDeselect item: FKListItemID) {
    updateSelectionStatus("Delegate didDeselect: \(item.rawValue)")
  }
}
