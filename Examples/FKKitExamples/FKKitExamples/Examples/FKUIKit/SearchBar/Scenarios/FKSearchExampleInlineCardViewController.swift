import FKUIKit
import UIKit

/// Full-width inline capsule preset (``.inlineCard``) above content.
final class FKSearchExampleInlineCardViewController: UIViewController, UITableViewDataSource {

  private let searchBar = FKSearchBar(configuration: FKSearchBarDefaults.inlineCard(), placeholder: "Search products")
  private let tableView = UITableView(frame: .zero, style: .plain)
  private var visibleItems = FKSearchExampleSupport.catalogItems

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Inline card"
    view.backgroundColor = .systemGroupedBackground

    searchBar.callbacks.onSearchQueryChanged = { [weak self] query in
      guard let self else { return }
      self.visibleItems = FKSearchExampleSupport.filter(FKSearchExampleSupport.catalogItems, query: query)
      self.tableView.reloadData()
    }

    tableView.dataSource = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

    let card = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel("`.inlineCard` preset: capsule chrome, no cancel column, debounced filter below."),
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
