import FKUIKit
import UIKit

/// Debounced ``searchQueryChanged`` vs raw ``textChanged`` with adjustable interval.
final class FKSearchExampleDebouncedFilterViewController: UIViewController, UITableViewDataSource {

  private let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.inlineCard(), placeholder: "Filter catalog")
  private let tableView = UITableView(frame: .zero, style: .plain)
  private let logView = FKSearchExampleSupport.makeEventLogTextView()
  private let intervalControl = UISegmentedControl(items: ["0.2s", "0.35s", "0.8s"])

  private var allItems = FKSearchExampleSupport.catalogItems
  private var visibleItems = FKSearchExampleSupport.catalogItems

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Debounced filter"
    view.backgroundColor = .systemGroupedBackground

    intervalControl.selectedSegmentIndex = 1
    intervalControl.addTarget(self, action: #selector(intervalChanged), for: .valueChanged)

    searchBar.callbacks.onTextChanged = { [weak self] text in
      guard let self else { return }
      FKSearchExampleSupport.appendLog(self.logView, "textChanged → \"\(text)\"")
    }
    searchBar.callbacks.onSearchQueryChanged = { [weak self] query in
      guard let self else { return }
      FKSearchExampleSupport.appendLog(self.logView, "searchQueryChanged → \"\(query)\"")
      self.visibleItems = FKSearchExampleSupport.filter(self.allItems, query: query)
      self.tableView.reloadData()
    }

    tableView.dataSource = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

    let header = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel("Type quickly — debounced callback coalesces keystrokes. Raw text fires every key."),
      searchBar,
      intervalControl,
    ])

    [header, tableView, logView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
    view.addSubview(header)
    view.addSubview(tableView)
    view.addSubview(logView)

    NSLayoutConstraint.activate([
      header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      header.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      header.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      tableView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

      logView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      logView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
      logView.heightAnchor.constraint(equalToConstant: 120),
    ])

    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear log", style: .plain, target: self, action: #selector(clearLog))
    intervalChanged()
  }

  @objc private func intervalChanged() {
    let interval: TimeInterval = switch intervalControl.selectedSegmentIndex {
    case 0: 0.2
    case 2: 0.8
    default: 0.35
    }
    searchBar.apply { $0.debounce.debounceInterval = interval }
    FKSearchExampleSupport.appendLog(logView, "debounceInterval = \(interval)s")
  }

  @objc private func clearLog() {
    logView.text = ""
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    visibleItems.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var config = cell.defaultContentConfiguration()
    config.text = visibleItems[indexPath.row]
    cell.contentConfiguration = config
    return cell
  }
}
