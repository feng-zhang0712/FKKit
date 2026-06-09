import FKUIKit
import UIKit

/// ``FKSearchField`` compact preset without a cancel column.
final class FKSearchExampleSearchFieldCompactViewController: UIViewController, UITableViewDataSource {

  private let searchField = FKSearchField(configuration: FKSearchFieldDefaults.compactFilter(), placeholder: "Filter in place")
  private let tableView = UITableView(frame: .zero, style: .plain)
  private var visibleItems = FKSearchExampleSupport.catalogItems

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKSearchField compact"
    view.backgroundColor = .systemGroupedBackground

    searchField.callbacks.onSearchQueryChanged = { [weak self] query in
      guard let self else { return }
      self.visibleItems = FKSearchExampleSupport.filter(FKSearchExampleSupport.catalogItems, query: query)
      self.tableView.reloadData()
    }

    tableView.dataSource = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

    let card = FKSearchExampleSupport.makeCardStack(arrangedSubviews: [
      FKSearchExampleSupport.makeCaptionLabel("Compact field for embedded filters — clear resets query; no cancel button."),
      searchField,
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
