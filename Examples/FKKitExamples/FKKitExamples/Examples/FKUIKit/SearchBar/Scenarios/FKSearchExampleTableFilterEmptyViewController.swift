import FKUIKit
import UIKit

/// UITableView filter driven by debounced query plus ``FKEmptyStateConfiguration/scenario(_:)`` when no matches.
final class FKSearchExampleTableFilterEmptyViewController: UIViewController, UITableViewDataSource {

  private let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.inlineCard(), placeholder: "Filter list")
  private let tableView = UITableView(frame: .zero, style: .insetGrouped)
  private var visibleItems = FKSearchExampleSupport.catalogItems

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Table + empty state"
    view.backgroundColor = .systemGroupedBackground

    searchBar.callbacks.onSearchQueryChanged = { [weak self] query in
      self?.applyFilter(query: query)
    }

    tableView.dataSource = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

    let card = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel("Non-empty query with zero rows shows `.noSearchResult` on the table."),
      searchBar,
    ])

    card.translatesAutoresizingMaskIntoConstraints = false
    tableView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(card)
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
      card.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      card.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

      tableView.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 12),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    applyFilter(query: "")
  }

  private func applyFilter(query: String) {
    visibleItems = FKSearchExampleSupport.filter(FKSearchExampleSupport.catalogItems, query: query)
    tableView.reloadData()

    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    let shouldShowEmpty = !trimmed.isEmpty && visibleItems.isEmpty
    var empty = FKEmptyStateConfiguration.scenario(.noSearchResult)
    empty.content.setImage(UIImage(systemName: "magnifyingglass"))
    tableView.fk_updateEmptyStateVisibility(isEmpty: shouldShowEmpty, configuration: empty, animated: true)
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
