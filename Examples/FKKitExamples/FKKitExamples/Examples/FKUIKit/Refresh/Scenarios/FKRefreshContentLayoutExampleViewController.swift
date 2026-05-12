import FKUIKit
import UIKit

/// Toggles ``FKRefreshConfiguration/defaultContentLayout`` on the bundled ``FKDefaultRefreshContentView`` (header + footer).
final class FKRefreshContentLayoutDemoViewController: UIViewController {

  private var items = (1...10).map { "Layout \($0)" }

  private lazy var tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.register(UITableViewCell.self, forCellReuseIdentifier: "c")
    tv.dataSource = self
    return tv
  }()

  private lazy var layoutSegment: UISegmentedControl = {
    let s = UISegmentedControl(items: ["Horizontal", "Vertical"])
    s.selectedSegmentIndex = 0
    s.addTarget(self, action: #selector(layoutChanged), for: .valueChanged)
    return s
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Indicator layout"
    view.backgroundColor = .systemGroupedBackground

    navigationItem.titleView = layoutSegment

    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    installControls()
  }

  @objc private func layoutChanged() {
    tableView.fk_removePullToRefresh()
    tableView.fk_removeLoadMore()
    installControls()
  }

  private func selectedLayout() -> FKDefaultRefreshContentLayout {
    layoutSegment.selectedSegmentIndex == 1 ? .vertical : .horizontal
  }

  private func installControls() {
    var cfg = FKRefreshConfiguration()
    cfg.defaultContentLayout = selectedLayout()
    cfg.tintColor = .systemIndigo

    tableView.fk_addPullToRefresh(configuration: cfg) { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 0.65) {
        guard let self else { return }
        self.items = (1...8).map { "Layout \($0)" }
        self.tableView.reloadData()
        self.tableView.fk_pullToRefresh?.endRefreshing()
        self.tableView.fk_loadMore?.resetToIdle()
      }
    }

    var loadCfg = cfg
    loadCfg.isSilentRefresh = false
    tableView.fk_addLoadMore(configuration: loadCfg) { [weak self] in
      FKRefreshExampleCommon.simulateRequest(delay: 0.55) {
        guard let self else { return }
        let n = self.items.count
        self.items.append(contentsOf: (n + 1...(n + 3)).map { "Layout \($0)" })
        self.tableView.reloadData()
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }
  }
}

extension FKRefreshContentLayoutDemoViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "c", for: indexPath)
    var c = cell.defaultContentConfiguration()
    c.text = items[indexPath.row]
    cell.contentConfiguration = c
    return cell
  }
}
