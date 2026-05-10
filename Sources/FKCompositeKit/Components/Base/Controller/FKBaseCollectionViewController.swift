import FKCoreKit
import FKUIKit
import UIKit

/// A ``FKBaseViewController`` specialization centered on a single primary ``UICollectionView``.
///
/// Mirrors ``FKBaseTableViewController``: safe-area + keyboard layout pinning, optional ``FKRefreshControl``
/// header/footer, and prefetch wiring when the subclass conforms to ``UICollectionViewDataSourcePrefetching``.
///
/// Supply a layout via ``init(collectionViewLayout:)``, or use ``init()`` / storyboard initializers for the default vertical flow layout.
/// Data source and delegate are **not** implemented here.
@MainActor
open class FKBaseCollectionViewController: FKBaseViewController {

  public let collectionView: UICollectionView

  public var isPullToRefreshEnabled: Bool = false

  public var isLoadMoreEnabled: Bool = false

  public private(set) var pullToRefreshControl: FKRefreshControl?

  public private(set) var loadMoreControl: FKRefreshControl?

  public private(set) var loadMoreState: FKBaseTableLoadMoreState = .idle

  /// Flow layout cast when the controller was created with ``UICollectionViewFlowLayout`` (including the default).
  public var flowLayout: UICollectionViewFlowLayout? {
    collectionView.collectionViewLayout as? UICollectionViewFlowLayout
  }

  // MARK: - Init

  /// Creates the controller with the given collection view layout.
  public init(collectionViewLayout: UICollectionViewLayout) {
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout)
    super.init(nibName: nil, bundle: nil)
    commonCollectionControllerInit()
  }

  /// Creates the controller with ``makeDefaultFlowLayout()``.
  public override init() {
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.makeDefaultFlowLayout())
    super.init()
    commonCollectionControllerInit()
  }

  public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.makeDefaultFlowLayout())
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    commonCollectionControllerInit()
  }

  public required init?(coder: NSCoder) {
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: Self.makeDefaultFlowLayout())
    super.init(coder: coder)
    commonCollectionControllerInit()
  }

  private func commonCollectionControllerInit() {
    disableScrollViewBounceByDefault = false
    collectionView.translatesAutoresizingMaskIntoConstraints = false
  }

  /// Default flow layout: vertical scrolling with estimated sizing-friendly defaults.
  open class func makeDefaultFlowLayout() -> UICollectionViewFlowLayout {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = 8.0
    layout.minimumInteritemSpacing = 8.0
    layout.sectionInset = UIEdgeInsets(top: 8.0, left: 16.0, bottom: 8.0, right: 16.0)
    layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
    return layout
  }

  // MARK: - Lifecycle

  open override func setupUI() {
    super.setupUI()
    view.insertSubview(collectionView, at: 0)
    configureCollectionView(collectionView)
  }

  open override func setupConstraints() {
    super.setupConstraints()
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
    ])
  }

  open override func setupBindings() {
    super.setupBindings()
    installRefreshControlsIfNeeded()
    if let prefetching = self as? UICollectionViewDataSourcePrefetching {
      collectionView.prefetchDataSource = prefetching
    } else {
      collectionView.prefetchDataSource = nil
    }
  }

  // MARK: - Configuration

  open func configureCollectionView(_ collectionView: UICollectionView) {
    collectionView.backgroundColor = .systemBackground
    collectionView.keyboardDismissMode = .onDrag
    collectionView.alwaysBounceVertical = true
  }

  open func performPullToRefresh() {
    endPullToRefresh(success: true)
  }

  open func performLoadMore() {
    markLoadMoreFinished()
  }

  // MARK: - Refresh helpers

  public func endPullToRefresh(success: Bool) {
    guard let control = pullToRefreshControl else { return }
    if success {
      control.endRefreshing()
    } else {
      control.endRefreshingWithError(nil)
    }
  }

  public func markLoadMoreFinished() {
    loadMoreState = .idle
    loadMoreControl?.endLoadingMore()
  }

  public func markLoadMoreNoMoreData() {
    loadMoreState = .completed
    loadMoreControl?.endRefreshingWithNoMoreData()
  }

  public func markLoadMoreFailed(_ error: Error? = nil) {
    loadMoreState = .failed
    loadMoreControl?.endRefreshingWithError(error)
  }

  public func scrollCollectionToTop(animated: Bool) {
    collectionView.fk_scrollToTop(animated: animated)
  }

  // MARK: - Private

  private var didInstallRefreshControls = false

  private func installRefreshControlsIfNeeded() {
    guard !didInstallRefreshControls else { return }
    didInstallRefreshControls = true

    if isPullToRefreshEnabled {
      pullToRefreshControl = collectionView.fk_addPullToRefresh { [weak self] in
        self?.handlePullToRefreshInvoked()
      }
    }

    if isLoadMoreEnabled {
      loadMoreControl = collectionView.fk_addLoadMore { [weak self] in
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
