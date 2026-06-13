import FKUIKit
import UIKit

/// Demonstrates debounced search filtering via ``applySnapshot(_:animatingDifferences:)``.
final class FKListKitSearchFilterExampleViewController: FKDiffableTableViewController, UISearchBarDelegate {
  private let searchBar = UISearchBar()
  private var didInstallSearchHeader = false
  private var allItems: [FKListItem] = []
  private var searchTask: Task<Void, Never>?

  init() {
    var config = FKListDefaults.defaultConfiguration
    config.search = FKListSearchConfiguration(clearsSelectionOnSearch: true, emptyScenario: .noSearchResult)
    config.empty.scenario = .noSearchResult
    config.refresh.isPullToRefreshEnabled = false
    config.refresh.isLoadMoreEnabled = false
    super.init(configuration: config)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Search Filter"

    allItems = (1 ... 30).map { index in
      let fruit = ["Apple", "Banana", "Cherry", "Date", "Fig"][(index - 1) % 5]
      return FKListItem.subtitle(id: FKListItemID("item-\(index)"), title: "\(fruit) #\(index)", subtitle: "Filter by fruit name")
    }
    applySnapshot(FKListSnapshot(items: allItems), animatingDifferences: false)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    guard tableView.bounds.width > 0 else { return }
    if !didInstallSearchHeader {
      didInstallSearchHeader = true
      installSearchHeader()
    } else {
      resizeSearchHeaderIfNeeded()
    }
  }

  private func installSearchHeader() {
    searchBar.placeholder = "Search fruits"
    searchBar.delegate = self
    searchBar.searchBarStyle = .minimal
    searchBar.autocapitalizationType = .none
    applySearchHeaderFrame()
  }

  private func resizeSearchHeaderIfNeeded() {
    guard let container = tableView.tableHeaderView else { return }
    let width = tableView.bounds.width
    guard abs(container.frame.width - width) > 0.5 else { return }
    applySearchHeaderFrame()
  }

  /// Frame-based header avoids Auto Layout conflicts with `UISearchBar` inside `tableHeaderView`.
  private func applySearchHeaderFrame() {
    let width = tableView.bounds.width
    let horizontalInset: CGFloat = 8
    let verticalInset: CGFloat = 4
    let barWidth = width - horizontalInset * 2
    let barHeight = searchBar.sizeThatFits(CGSize(width: barWidth, height: .greatestFiniteMagnitude)).height
    let totalHeight = barHeight + verticalInset * 2

    searchBar.frame = CGRect(x: horizontalInset, y: verticalInset, width: barWidth, height: barHeight)

    let container: UIView
    if let existing = tableView.tableHeaderView {
      container = existing
    } else {
      container = UIView()
      container.backgroundColor = .systemBackground
      container.addSubview(searchBar)
    }
    container.frame = CGRect(x: 0, y: 0, width: width, height: totalHeight)
    tableView.tableHeaderView = container
  }

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    scheduleFilter(query: searchText)
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
  }

  private func scheduleFilter(query: String) {
    searchTask?.cancel()
    searchTask = Task { @MainActor [weak self] in
      try? await Task.sleep(nanoseconds: 250_000_000)
      guard let self, !Task.isCancelled else { return }
      self.applyFilteredSnapshot(for: query)
    }
  }

  private func applyFilteredSnapshot(for query: String) {
    if configuration.search?.clearsSelectionOnSearch == true {
      tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: false) }
    }
    let filtered: [FKListItem]
    if query.isEmpty {
      activeEmptyScenarioOverride = nil
      filtered = allItems
    } else {
      filtered = allItems.filter { item in
        guard case .preset(.subtitle(let row)) = item.kind else { return false }
        return row.title.localizedCaseInsensitiveContains(query)
      }
      activeEmptyScenarioOverride = filtered.isEmpty ? configuration.search?.emptyScenario : nil
    }
    applySnapshot(FKListSnapshot(items: filtered), animatingDifferences: true)
  }
}
