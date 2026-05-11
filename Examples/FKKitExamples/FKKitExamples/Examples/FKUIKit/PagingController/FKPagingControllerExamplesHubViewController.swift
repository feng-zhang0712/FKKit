import UIKit

/// Index of `FKPagingController` scenarios: UIKit, SwiftUI, delegate hooks, and dynamic updates.
final class FKPagingControllerExamplesHubViewController: UITableViewController {
  private struct RowModel {
    let title: String
    let subtitle: String
    let make: () -> UIViewController
  }

  private let rows: [RowModel] = {
    var list: [RowModel] = [
      RowModel(
        title: "Basics (eager)",
        subtitle: "Two-way tab sync, nested list, Stress x20 queue test (non-animated bursts).",
        make: { FKPagingBasicsExampleViewController() }
      ),
      RowModel(
        title: "Delegate & configuration",
        subtitle: "Phase/progress logging, swipe toggle, gesture policy, alwaysCenter tab alignment.",
        make: { FKPagingDelegateConfigurationExampleViewController() }
      ),
      RowModel(
        title: "Dynamic setContent",
        subtitle: "Toggle between 3 and 8 tabs to exercise reload + selection preservation.",
        make: { FKPagingDynamicContentExampleViewController() }
      ),
      RowModel(
        title: "Lazy pages (UIKit)",
        subtitle: "Factory-driven pages, preload range, keepNear cache eviction, creation counter.",
        make: { FKPagingLazyPagesExampleViewController() }
      ),
    ]
    #if canImport(SwiftUI)
    list.append(
      contentsOf: [
        RowModel(
          title: "SwiftUI lazy provider",
          subtitle: "FKPagingControllerRepresentable with pageCount + factory closure binding.",
          make: { FKPagingLazySwiftUIExampleViewController() }
        ),
        RowModel(
          title: "SwiftUI representable",
          subtitle: "Eager pages with $selectedIndex mirrored under the pager.",
          make: { FKPagingSwiftUIBridgeExampleViewController() }
        ),
      ]
    )
    #endif
    return list.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
  }()

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
