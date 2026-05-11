import UIKit

/// Entry list for FKCompositeKit Base module demos (each row maps to one scenario file).
final class FKBaseExamplesHubViewController: UITableViewController {

  private enum Row: Int, CaseIterable {
    case viewController
    case table
    case collection
    case composition
    case search

    var title: String {
      switch self {
      case .viewController: return "FKBaseViewController"
      case .table: return "FKBaseTableViewController"
      case .collection: return "FKBaseCollectionViewController"
      case .composition: return "Composition (no base VC)"
      case .search: return "Search + FKBaseSearchIntegration"
      }
    }

    var subtitle: String {
      switch self {
      case .viewController:
        return "Lifecycle, overlays, toast, keyboard, nav chrome, loadInitialContent"
      case .table:
        return "Primary UITableView, pull-to-refresh, load-more, prefetch hook"
      case .collection:
        return "Primary UICollectionView, flow layout, refresh footer/header"
      case .composition:
        return "FKViewControllerComposite + build phases + lifecycle forwarding"
      case .search:
        return "UISearchController embedded via navigationItem"
      }
    }

    func makeDestination() -> UIViewController {
      switch self {
      case .viewController: return FKBaseViewControllerExampleViewController()
      case .table: return FKBaseTableViewControllerExampleViewController()
      case .collection: return FKBaseCollectionViewControllerExampleViewController()
      case .composition: return FKBaseCompositionExampleViewController()
      case .search: return FKBaseSearchExampleViewController()
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Base"
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
    var content = cell.defaultContentConfiguration()
    content.text = row.title
    content.secondaryText = row.subtitle
    content.secondaryTextProperties.color = .secondaryLabel
    cell.contentConfiguration = content
    cell.accessoryType = .disclosureIndicator
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    navigationController?.pushViewController(Row.allCases[indexPath.row].makeDestination(), animated: true)
  }
}
