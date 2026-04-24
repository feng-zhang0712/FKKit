import UIKit

final class FKPagingControllerExamplesHubViewController: UITableViewController {
  private struct RowModel {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [RowModel] = [
    RowModel(
      title: "FKPagingController + FKTabBar two-way sync",
      subtitle: "Verifies tab tap to page switching and interactive page dragging progress feedback to tab indicator.",
      make: { FKPagingControllerBasicExampleViewController() }
    ),
  ]

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "PagingController"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
  }

  override func numberOfSections(in tableView: UITableView) -> Int { 1 }

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
