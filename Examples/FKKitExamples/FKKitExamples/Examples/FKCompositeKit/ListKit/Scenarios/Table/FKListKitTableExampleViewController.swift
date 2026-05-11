import FKCompositeKit
import FKUIKit
import UIKit

// MARK: - Model

struct DemoItemModel: Equatable, Hashable {
  let id: String
  let title: String
  let content: String
}

// MARK: - Cell

/// Uses ``FKBaseTableViewCell`` as the reusable root while conforming to ``FKListTableCellConfigurable``.
final class DemoItemCell: FKBaseTableViewCell, FKListTableCellConfigurable {

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func configure(with item: DemoItemModel) {
    var config = defaultContentConfiguration()
    config.text = item.title
    config.secondaryText = item.content
    config.secondaryTextProperties.numberOfLines = 2
    config.secondaryTextProperties.color = .secondaryLabel
    contentConfiguration = config
    accessoryType = .none
  }
}

// MARK: - Mock service

nonisolated private final class DemoListMockService: @unchecked Sendable {

  enum Outcome {
    case items([DemoItemModel])
    case empty
    case failure(message: String)
  }

  var forceNextRefreshEmpty = false
  var forceNextFailure = false
  var refreshItemCountRange: ClosedRange<Int> = 4...12
  var loadMorePageSize: Int = 8

  private let queue = DispatchQueue(label: "demo.list.mock", qos: .userInitiated)

  nonisolated func simulateRequest(
    page: Int,
    limit: Int,
    isFirstPage: Bool,
    completion: @escaping @MainActor (Outcome) -> Void
  ) {
    queue.async { [weak self] in
      guard let self else { return }
      Thread.sleep(forTimeInterval: Double.random(in: 0.35...0.85))
      let outcome: Outcome
      if self.forceNextFailure {
        self.forceNextFailure = false
        outcome = .failure(message: "Forced demo failure (simulating a 503).")
      } else if isFirstPage, Double.random(in: 0...1) < 0.06 {
        outcome = .failure(message: "Refresh failed. Please try again.")
      } else if isFirstPage, self.forceNextRefreshEmpty {
        self.forceNextRefreshEmpty = false
        outcome = .empty
      } else if !isFirstPage, Double.random(in: 0...1) < 0.12 {
        outcome = .failure(message: "Load more failed. Please retry.")
      } else if isFirstPage, Double.random(in: 0...1) < 0.08 {
        outcome = .empty
      } else if !isFirstPage, Double.random(in: 0...1) < 0.1 {
        outcome = .failure(message: "Network is unstable. Please try again later.")
      } else {
        let count: Int
        if isFirstPage {
          count = Int.random(in: self.refreshItemCountRange)
        } else {
          count = min(limit, self.loadMorePageSize)
        }
        let base = (page - 1) * limit
        let items = (0..<count).map { offset -> DemoItemModel in
          let index = base + offset
          return DemoItemModel(
            id: "demo-\(index)",
            title: "Page \(page) · Row \(offset + 1)",
            content: "Placeholder copy #\(index). Replace with your own summary in production."
          )
        }
        outcome = .items(items)
      }
      DispatchQueue.main.async {
        completion(outcome)
      }
    }
  }
}

// MARK: - View controller

final class FKListKitTableExampleViewController: UIViewController, FKListScreen {

  var listPlugins: [FKListPlugin] { [listPlugin] }

  private let tableView: UITableView = {
    let tv = UITableView(frame: .zero, style: .insetGrouped)
    tv.translatesAutoresizingMaskIntoConstraints = false
    tv.keyboardDismissMode = .onDrag
    return tv
  }()

  private let skeletonHost = FKSkeletonContainerView()
  private let mockService = DemoListMockService()

  private lazy var listPlugin: FKListPlugin = {
    var configuration = FKListConfiguration()
    configuration.pagination = FKPageManagerConfiguration(pageSize: 8, mode: .page(firstPageIndex: 1))
    configuration.enablesPullToRefresh = true
    configuration.enablesLoadMore = true
    configuration.enablesSkeletonOnInitialLoad = true
    configuration.presentsEmptyStateOverlay = true
    configuration.presentsErrorStateOverlay = true
    configuration.tracksItemCountForRefreshFailureUX = true
    configuration.hasMoreEvaluator = { [weak self] _, _ in
      guard let self else { return false }
      let page = self.listPlugin.pageManager.lastSuccessfulPage ?? 0
      return page < 3
    }
    return FKListPlugin(configuration: configuration)
  }()

  private var items: [DemoItemModel] = []

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ListKit · Table"
    view.backgroundColor = .systemBackground
    configureNavigationItems()
    configureHierarchy()
    configureTable()
    buildSkeletonLayout()
    mountListPlugin()
    startRefresh()
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isMovingFromParent || isBeingDismissed {
      detachAllListPlugins()
    }
  }

  private func configureNavigationItems() {
    navigationItem.rightBarButtonItems = [
      UIBarButtonItem(title: "Next empty", style: .plain, target: self, action: #selector(toggleNextEmpty)),
      UIBarButtonItem(title: "Next failure", style: .plain, target: self, action: #selector(toggleNextFailure)),
    ]
  }

  @objc private func toggleNextEmpty() {
    mockService.forceNextRefreshEmpty.toggle()
    presentToast(mockService.forceNextRefreshEmpty ? "Next refresh → empty." : "Forced empty off.")
  }

  @objc private func toggleNextFailure() {
    mockService.forceNextFailure.toggle()
    presentToast(mockService.forceNextFailure ? "Next request → failure." : "Forced failure off.")
  }

  private func presentToast(_ message: String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    present(alert, animated: true)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak alert] in
      alert?.dismiss(animated: true)
    }
  }

  private func configureHierarchy() {
    skeletonHost.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(skeletonHost)
    view.addSubview(tableView)

    NSLayoutConstraint.activate([
      skeletonHost.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      skeletonHost.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      skeletonHost.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      skeletonHost.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func configureTable() {
    tableView.dataSource = self
    tableView.register(DemoItemCell.self, forCellReuseIdentifier: DemoItemCell.reuseIdentifier)
  }

  private func buildSkeletonLayout() {
    skeletonHost.removeAllSkeletonSubviews()
    var previous: FKSkeletonView?
    for _ in 0..<8 {
      let row = FKSkeletonView()
      row.translatesAutoresizingMaskIntoConstraints = false
      row.heightAnchor.constraint(equalToConstant: 56).isActive = true
      row.layer.cornerRadius = 10
      row.clipsToBounds = true
      skeletonHost.addSkeletonSubview(row)
      NSLayoutConstraint.activate([
        row.leadingAnchor.constraint(equalTo: skeletonHost.leadingAnchor, constant: 20),
        row.trailingAnchor.constraint(equalTo: skeletonHost.trailingAnchor, constant: -20),
      ])
      if let previous {
        row.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: 12).isActive = true
      } else {
        row.topAnchor.constraint(equalTo: skeletonHost.topAnchor, constant: 24).isActive = true
      }
      previous = row
    }
    if let previous {
      previous.bottomAnchor.constraint(lessThanOrEqualTo: skeletonHost.bottomAnchor, constant: -16).isActive = true
    }
  }

  private func mountListPlugin() {
    listPlugin.currentTotalItemCount = { [weak self] in
      self?.items.count ?? 0
    }

    listPlugin.onRefresh = { [weak self] parameters in
      self?.handleRefreshLikeRequest(parameters: parameters)
    }

    listPlugin.onLoadMore = { [weak self] parameters in
      self?.handleLoadMoreRequest(parameters: parameters)
    }

    listPlugin.onEmptyOrErrorOverlayPrimaryAction = { [weak self] in
      self?.startRefresh()
    }

    listPlugin.attach(
      scrollView: tableView,
      emptyStateHost: view,
      skeletonHost: skeletonHost,
      hostViewController: self
    )
  }

  private func startRefresh() {
    listPlugin.startInitialLoad()
  }

  private func handleRefreshLikeRequest(parameters: FKPageRequestParameters) {
    let page = parameters.page ?? 1
    mockService.simulateRequest(page: page, limit: parameters.limit, isFirstPage: true) { [weak self] outcome in
      guard let self else { return }
      switch outcome {
      case .items(let batch):
        self.items = batch
        self.tableView.reloadData()
        self.listPlugin.handleSuccess(
          fetchedThisBatchCount: batch.count,
          totalItemCountAfterMerge: self.items.count
        )
      case .empty:
        self.items = []
        self.tableView.reloadData()
        self.listPlugin.handleSuccess(fetchedThisBatchCount: 0, totalItemCountAfterMerge: 0)
      case .failure(let message):
        self.listPlugin.handleError(
          DemoListError.stub(message),
          listError: .business(code: "DEMO", message: message)
        )
      }
    }
  }

  private func handleLoadMoreRequest(parameters: FKPageRequestParameters) {
    let page = parameters.page ?? 1
    mockService.simulateRequest(page: page, limit: parameters.limit, isFirstPage: false) { [weak self] outcome in
      guard let self else { return }
      switch outcome {
      case .items(let batch):
        self.items.append(contentsOf: batch)
        self.tableView.reloadData()
        self.listPlugin.handleSuccess(
          fetchedThisBatchCount: batch.count,
          totalItemCountAfterMerge: self.items.count
        )
      case .empty:
        self.tableView.reloadData()
        self.listPlugin.handleSuccess(fetchedThisBatchCount: 0, totalItemCountAfterMerge: self.items.count)
      case .failure(let message):
        self.listPlugin.handleError(
          DemoListError.stub(message),
          listError: .business(code: "DEMO_LOAD_MORE", message: message)
        )
      }
    }
  }
}

extension FKListKitTableExampleViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    items.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: DemoItemCell.reuseIdentifier, for: indexPath) as! DemoItemCell
    cell.configure(with: items[indexPath.row])
    return cell
  }
}

private struct DemoListError: LocalizedError {
  let message: String
  var errorDescription: String? { message }

  static func stub(_ message: String) -> DemoListError {
    DemoListError(message: message)
  }
}
