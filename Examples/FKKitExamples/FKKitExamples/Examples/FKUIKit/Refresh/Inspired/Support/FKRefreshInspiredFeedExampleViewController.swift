import FKUIKit
import UIKit

/// Reusable table feed that applies an ``FKRefreshAppStylePreset`` to header and footer controls.
final class FKRefreshInspiredFeedExampleViewController: UITableViewController {

  private let preset: FKRefreshAppStylePreset.Bundle
  private var items: [String]
  private var simulateFailure = false
  private var installedSummaryHeaderSize: CGSize = .zero

  private lazy var summaryHeader: UIView = {
    let container = UIView()
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.text = preset.summary
    label.setContentCompressionResistancePriority(.required, for: .vertical)
    container.addSubview(label)
    NSLayoutConstraint.activate([
      label.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
      label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
      label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
      label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
    ])
    return container
  }()

  init(preset: FKRefreshAppStylePreset.Bundle) {
    self.preset = preset
    items = (0..<preset.initialCount).map { "Row \($0)" }
    super.init(style: .plain)
    title = preset.screenTitle
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    tableView.backgroundColor = .systemGroupedBackground

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: simulateFailure ? "Fail: On" : "Fail: Off",
      style: .plain,
      target: self,
      action: #selector(toggleFailureMode)
    )

    installRefreshControls()
    tableView.fk_beginPullToRefresh(animated: true)
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    updateSummaryHeaderIfNeeded()
  }

  @objc private func toggleFailureMode() {
    simulateFailure.toggle()
    navigationItem.rightBarButtonItem?.title = simulateFailure ? "Fail: On" : "Fail: Off"
    tableView.fk_pullToRefresh?.cancelCurrentAction(resetState: true)
    tableView.fk_loadMore?.cancelCurrentAction(resetState: true)
    items = (0..<preset.initialCount).map { "Row \($0)" }
    tableView.reloadData()
    tableView.fk_loadMore?.resetFooterAfterPullToRefresh()
  }

  /// Sizes the description header once `tableView` has a non-zero width (avoids zero-width Auto Layout warnings).
  private func updateSummaryHeaderIfNeeded() {
    let width = tableView.bounds.width
    guard width > 0 else { return }

    let header = summaryHeader
    let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
    let height = ceil(
      header.systemLayoutSizeFitting(
        target,
        withHorizontalFittingPriority: .required,
        verticalFittingPriority: .fittingSizeLevel
      ).height
    )
    let size = CGSize(width: width, height: height)
    guard height > 0, installedSummaryHeaderSize != size else { return }

    header.frame = CGRect(origin: .zero, size: size)
    tableView.tableHeaderView = header
    installedSummaryHeaderSize = size
  }

  private func installRefreshControls() {
    tableView.fk_removePullToRefresh()
    tableView.fk_removeLoadMore()

    tableView.fk_addPullToRefresh(configuration: preset.header) { [weak self] in
      self?.performPullToRefresh()
    }

    tableView.fk_addLoadMore(configuration: preset.footer) { [weak self] in
      self?.performLoadMore()
    }
  }

  private func performPullToRefresh() {
    FKRefreshExampleCommon.simulateRequest(delay: preset.requestDelay) { [weak self] in
      guard let self else { return }
      if self.simulateFailure {
        self.tableView.fk_pullToRefresh?.endRefreshingWithError()
        return
      }
      self.items = (0..<self.preset.initialCount).map { "Row \($0)" }
      self.tableView.reloadData()
      self.tableView.fk_pullToRefresh?.endRefreshing()
      self.tableView.fk_loadMore?.resetFooterAfterPullToRefresh()
    }
  }

  private func performLoadMore() {
    FKRefreshExampleCommon.simulateRequest(delay: preset.requestDelay) { [weak self] in
      guard let self else { return }
      if self.simulateFailure {
        self.tableView.fk_loadMore?.endRefreshingWithError()
        return
      }
      if self.items.count >= self.preset.maxItems {
        self.tableView.fk_loadMore?.endRefreshingWithNoMoreData()
        return
      }
      let start = self.items.count
      let end = min(start + self.preset.pageSize, self.preset.maxItems)
      self.items.append(contentsOf: (start..<end).map { "Row \($0)" })
      self.tableView.reloadData()
      if self.items.count >= self.preset.maxItems {
        self.tableView.fk_loadMore?.endRefreshingWithNoMoreData()
      } else {
        self.tableView.fk_loadMore?.endRefreshing()
      }
    }
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
    var content = cell.defaultContentConfiguration()
    content.text = items[indexPath.row]
    cell.contentConfiguration = content
    return cell
  }
}
