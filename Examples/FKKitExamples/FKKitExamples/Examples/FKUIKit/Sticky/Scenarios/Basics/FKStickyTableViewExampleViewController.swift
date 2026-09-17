import FKUIKit
import UIKit

/// Sticky strip hosted inside a fixed-height `tableHeaderView` (not a free `UITableView` subview).
///
/// Arbitrary non-cell subviews on `UITableView` are rewritten during table layout and amplify
/// bottom rubber-band jitter. Fixed `rowHeight` / `estimatedRowHeight` keep `contentSize` stable
/// so max-offset clamping does not fight the bounce.
final class FKStickyTableViewExampleViewController: UIViewController, UITableViewDataSource {
  private let tableView = UITableView(frame: .zero, style: .plain)
  private let statusLabel = FKStickyExampleUI.statusLabel()
  private let headerContainer = UIView()
  private let strip = FKStickyExampleStripView(title: "Table filters", backgroundColor: .systemIndigo)
  private let rows = (0..<40).map { "Row \($0 + 1)" }
  private let stripHeight: CGFloat = 48
  private let stripTop: CGFloat = 12
  private let rowHeight: CGFloat = 44
  private var didInstallSticky = false
  private var lastHeaderWidth: CGFloat = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "UITableView"
    view.backgroundColor = .systemBackground

    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.dataSource = self
    tableView.contentInsetAdjustmentBehavior = .never
    tableView.rowHeight = rowHeight
    tableView.estimatedRowHeight = rowHeight
    tableView.estimatedSectionHeaderHeight = 0
    tableView.estimatedSectionFooterHeight = 0
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0
    }
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    view.addSubview(tableView)

    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(statusLabel)

    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      statusLabel.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      statusLabel.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
    ])

    headerContainer.backgroundColor = .clear
    strip.translatesAutoresizingMaskIntoConstraints = true
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateHeaderGeometryIfNeeded()
    installStickyIfNeeded()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // First layout may finish after the initial scroll gesture begins — remasure so the
    // first drag already sticks once the strip crosses the pin line.
    updateHeaderGeometryIfNeeded()
    installStickyIfNeeded()
    tableView.fk_reloadStickyLayout()
  }

  private func updateHeaderGeometryIfNeeded() {
    let tableWidth = tableView.bounds.width
    guard tableWidth > 1 else { return }

    let headerHeight = stripTop + stripHeight + 12
    let widthChanged = abs(tableWidth - lastHeaderWidth) > 0.5
    guard tableView.tableHeaderView == nil || widthChanged else { return }

    lastHeaderWidth = tableWidth
    headerContainer.frame = CGRect(x: 0, y: 0, width: tableWidth, height: headerHeight)
    if strip.superview === headerContainer || strip.superview == nil {
      strip.frame = CGRect(x: 16, y: stripTop, width: tableWidth - 32, height: stripHeight)
    }
    if strip.superview !== headerContainer {
      headerContainer.addSubview(strip)
    }
    // Re-assign only when geometry changes — avoids max-offset clamp jitter mid-scroll.
    tableView.tableHeaderView = headerContainer
  }

  private func installStickyIfNeeded() {
    guard !didInstallSticky, tableView.bounds.width > 1, tableView.tableHeaderView != nil else { return }
    didInstallSticky = true
    if strip.superview !== headerContainer {
      headerContainer.addSubview(strip)
      tableView.tableHeaderView = headerContainer
    }
    tableView.fk_addStickyTarget(id: "table-filters", view: strip) { [weak self] progress in
      self?.statusLabel.text =
        "table-filters → \(progress.state.rawValue) p=\(String(format: "%.2f", progress.value))"
    }
    tableView.fk_reloadStickyLayout()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    rows.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = rows[indexPath.row]
    cell.contentConfiguration = config
    return cell
  }
}
