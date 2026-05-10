import FKCompositeKit
import FKUIKit
import UIKit

/// Demonstrates ``FKBaseTableViewController``: primary table, pull-to-refresh, load-more, and ``loadInitialContent``.
final class FKBaseTableViewControllerExampleViewController: FKBaseTableViewController, UITableViewDataSource {

  private var rows: [String] = []
  private var loadMorePages = 0

  init() {
    super.init(style: .insetGrouped)
    isPullToRefreshEnabled = true
    isLoadMoreEnabled = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "FKBaseTableViewController"
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Reload",
      style: .plain,
      target: self,
      action: #selector(manualReload)
    )
  }

  override func configureTableView(_ tableView: UITableView) {
    super.configureTableView(tableView)
    tableView.dataSource = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
  }

  override func loadInitialContent() {
    super.loadInitialContent()
    rows = (0..<12).map { "Row \($0 + 1) (initial)" }
    tableView.reloadData()
  }

  override func performPullToRefresh() {
    loadMorePages = 0
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
      guard let self else { return }
      self.rows = (0..<10).map { "Row \($0 + 1) (refreshed)" }
      self.tableView.reloadData()
      self.endPullToRefresh(success: true)
    }
  }

  override func performLoadMore() {
    loadMorePages += 1
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
      guard let self else { return }
      if self.loadMorePages >= 3 {
        self.markLoadMoreNoMoreData()
        return
      }
      let start = self.rows.count
      self.rows.append(contentsOf: (0..<5).map { "Row \(start + $0 + 1) (page \(self.loadMorePages))" })
      self.tableView.reloadData()
      self.markLoadMoreFinished()
    }
  }

  @objc private func manualReload() {
    tableView.fk_beginPullToRefresh(animated: true)
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

extension FKBaseTableViewControllerExampleViewController: UITableViewDataSourcePrefetching {
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    // Demo hook only — real apps prefetch images or warm caches here.
  }
}
