import FKCoreKit
import FKUIKit
import UIKit

/// A `FKBaseViewController` specialization centered on a single primary `UITableView`.
///
/// Responsibilities:
/// - Pins the table to the safe area and ``UIView/keyboardLayoutGuide`` (iOS 15+) for keyboard avoidance.
/// - Keeps vertical bounce enabled for pull-to-refresh ergonomics (see ``disableScrollViewBounceByDefault``).
/// - Optionally wires ``FKRefreshControl`` pull and load-more footers via ``isPullToRefreshEnabled`` /
///   ``isLoadMoreEnabled``.
///
/// Data source and delegate are **not** implemented here; subclasses assign ``UITableView/dataSource``
/// and ``UITableView/delegate`` (and may use `UITableViewDiffableDataSource` independently).
@MainActor
open class FKBaseTableViewController: FKBaseViewController {

  // MARK: - Public surface

  /// Primary list view. Created with ``init(style:)`` / storyboard initializers.
  public let tableView: UITableView

  /// When `true`, installs ``UIScrollView/fk_addPullToRefresh(configuration:action:)`` during ``setupBindings()``.
  public var isPullToRefreshEnabled: Bool = false

  /// When `true`, installs ``UIScrollView/fk_addLoadMore(configuration:action:)`` during ``setupBindings()``.
  public var isLoadMoreEnabled: Bool = false

  /// Attached header control, if ``isPullToRefreshEnabled`` is `true` after ``setupBindings()``.
  public private(set) var pullToRefreshControl: FKRefreshControl?

  /// Attached footer control, if ``isLoadMoreEnabled`` is `true` after ``setupBindings()`.
  public private(set) var loadMoreControl: FKRefreshControl?

  /// High-level pagination hint for load-more UX (call ``markLoadMoreFinished()`` / ``markLoadMoreNoMoreData()`` from your fetch logic).
  public private(set) var loadMoreState: FKBaseTableLoadMoreState = .idle

  // MARK: - Init

  /// Designated style-based initializer.
  public init(style: UITableView.Style = .plain) {
    self.tableView = UITableView(frame: .zero, style: style)
    super.init(nibName: nil, bundle: nil)
    commonTableControllerInit()
  }

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    self.tableView = UITableView(frame: .zero, style: .plain)
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    commonTableControllerInit()
  }

  public required init?(coder: NSCoder) {
    self.tableView = UITableView(frame: .zero, style: .plain)
    super.init(coder: coder)
    commonTableControllerInit()
  }

  private func commonTableControllerInit() {
    // Lists rely on vertical bounce for pull-to-refresh; do not inherit the global “disable all bounce” default.
    disableScrollViewBounceByDefault = false
    tableView.translatesAutoresizingMaskIntoConstraints = false
  }

  // MARK: - Lifecycle

  open override func setupUI() {
    super.setupUI()
    view.insertSubview(tableView, at: 0)
    configureTableView(tableView)
  }

  open override func setupConstraints() {
    super.setupConstraints()
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
    ])
  }

  open override func setupBindings() {
    super.setupBindings()
    installRefreshControlsIfNeeded()
    if let prefetching = self as? UITableViewDataSourcePrefetching {
      tableView.prefetchDataSource = prefetching
    } else {
      tableView.prefetchDataSource = nil
    }
  }

  // MARK: - Overridable configuration

  /// One-time table configuration (style is fixed by the initializer). Default enables self-sizing rows
  /// and separator behavior suitable for most apps.
  open func configureTableView(_ tableView: UITableView) {
    tableView.backgroundColor = .systemBackground
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 44.0
    tableView.keyboardDismissMode = .onDrag
    if #available(iOS 15.0, *) {
      tableView.sectionHeaderTopPadding = 0.0
    }
  }

  /// Called when pull-to-refresh fires. Override to load the first page / reload.
  ///
  /// When finished, call ``endPullToRefresh(success:)`` (or ``FKRefreshControl`` APIs directly).
  open func performPullToRefresh() {
    endPullToRefresh(success: true)
  }

  /// Called when the load-more footer fires. Override to fetch the next page.
  ///
  /// When finished, call ``markLoadMoreFinished()`` or ``markLoadMoreNoMoreData()`` as appropriate.
  open func performLoadMore() {
    markLoadMoreFinished()
  }

  // MARK: - Public refresh helpers

  /// Ends the pull-to-refresh header using ``FKRefreshControl`` outcome helpers.
  public func endPullToRefresh(success: Bool) {
    guard let control = pullToRefreshControl else { return }
    if success {
      control.endRefreshing()
    } else {
      control.endRefreshingWithError(nil)
    }
  }

  /// Marks a successful load-more cycle (more pages may exist).
  public func markLoadMoreFinished() {
    loadMoreState = .idle
    loadMoreControl?.endLoadingMore()
  }

  /// Marks pagination as exhausted (disables further footer loading UX).
  public func markLoadMoreNoMoreData() {
    loadMoreState = .completed
    loadMoreControl?.endRefreshingWithNoMoreData()
  }

  /// Marks load-more failure while keeping existing rows visible.
  public func markLoadMoreFailed(_ error: Error? = nil) {
    loadMoreState = .failed
    loadMoreControl?.endRefreshingWithError(error)
  }

  /// Scrolls the table to the top using ``UIScrollView/fk_scrollToTop(animated:)``.
  public func scrollTableToTop(animated: Bool) {
    tableView.fk_scrollToTop(animated: animated)
  }

  // MARK: - Private

  private var didInstallRefreshControls = false

  private func installRefreshControlsIfNeeded() {
    guard !didInstallRefreshControls else { return }
    didInstallRefreshControls = true

    if isPullToRefreshEnabled {
      pullToRefreshControl = tableView.fk_addPullToRefresh { [weak self] in
        self?.handlePullToRefreshInvoked()
      }
    }

    if isLoadMoreEnabled {
      loadMoreControl = tableView.fk_addLoadMore { [weak self] in
        self?.handleLoadMoreInvoked()
      }
    }
  }

  private func handlePullToRefreshInvoked() {
    performPullToRefresh()
  }

  private func handleLoadMoreInvoked() {
    guard loadMoreState != .completed else {
      loadMoreControl?.endRefreshingWithNoMoreData()
      return
    }
    guard loadMoreState != .loading else { return }
    loadMoreState = .loading
    performLoadMore()
  }
}
