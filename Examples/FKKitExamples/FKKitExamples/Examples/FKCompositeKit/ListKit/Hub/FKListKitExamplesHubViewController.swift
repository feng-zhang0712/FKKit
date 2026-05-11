import UIKit

/// Entry list for ListKit demos.
final class FKListKitExamplesHubViewController: UITableViewController {

  private enum Row: Int, CaseIterable {
    case tablePlugin

    var title: String {
      switch self {
      case .tablePlugin:
        return "Table + FKListPlugin"
      }
    }

    var subtitle: String {
      switch self {
      case .tablePlugin:
        return "Paging, refresh, skeleton, empty/error, FKListScreen, FKBaseTableViewCell"
      }
    }

    func makeDestination() -> UIViewController {
      switch self {
      case .tablePlugin:
        return FKListKitTableExampleViewController()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ListKit"
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.cellLayoutMarginsFollowReadableWidth = true
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    Row.allCases.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    let row = Row.allCases[indexPath.row]
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
    navigationController?.pushViewController(Row.allCases[indexPath.row].makeDestination(), animated: true)
  }
}
