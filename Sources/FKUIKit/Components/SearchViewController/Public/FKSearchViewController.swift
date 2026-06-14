import UIKit

/// Composes ``FKSearchBar``, ``FKDiffableTableViewController``, empty/error states, and optional remote search.
///
/// Assign ``localFilterProvider`` or ``resultsProvider`` before the first search. Use ``configuration`` for mode,
/// placement, and loading behavior.
@MainActor
open class FKSearchViewController: UIViewController {
  public var configuration: FKSearchViewControllerConfiguration {
    didSet { applyConfiguration() }
  }

  public private(set) var searchBar: FKSearchBar
  public private(set) var listViewController: FKDiffableTableViewController!
  public private(set) var presentationState: FKSearchPresentationState = .idle

  public var callbacks = FKSearchViewControllerCallbacks()
  public weak var delegate: FKSearchViewControllerDelegate?

  /// Required for ``FKSearchMode/localFilter``.
  public weak var localFilterProvider: FKSearchLocalFilterProviding?
  /// Required for ``FKSearchMode/remote``.
  public weak var resultsProvider: FKSearchResultsProviding?

  /// Snapshot restored when remote query is empty and ``FKSearchBehaviorConfiguration/showsResultsOnEmptyQuery`` is `true`.
  public var remoteIdleSnapshot: FKListSnapshot = FKListSnapshot()

  private let sessionCoordinator = FKSearchSessionCoordinator()
  private var chromeContainer: FKSearchChromeContainerView?
  private var listTopConstraint: NSLayoutConstraint?
  private var currentQuery = ""
  private var didInstallInitialContent = false
  private var didFocusSearchOnAppear = false
  private var isShowingSearchSkeleton = false
  private var didInstallTableHeader = false

  public init(
    configuration: FKSearchViewControllerConfiguration = FKSearchViewControllerDefaults.localFilter(),
    placeholder: String? = nil
  ) {
    self.configuration = configuration
    self.searchBar = FKSearchBar(configuration: configuration.searchBar, placeholder: placeholder)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    sessionCoordinator.cancelAll()
  }

  // MARK: - Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.largeTitleDisplayMode = .never
    view.backgroundColor = .systemBackground
    listViewController = makeListViewController()
    listViewController.delegate = self
    configureSearchBar(searchBar)
    wireSearchBarCallbacks()
    embedListViewController()
    installSearchPlacement()
    applyConfiguration()
  }

  open override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    refreshNavigationBarSearchPlacementIfNeeded()
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if configuration.behavior.focusesSearchOnAppear, !didFocusSearchOnAppear {
      didFocusSearchOnAppear = true
      searchBar.textField.becomeFirstResponder()
    }
    installInitialContentIfNeeded()
  }

  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if configuration.placement == .tableHeader {
      FKSearchTableHeaderInstaller.refresh(listViewController.tableView)
    }
  }

  open override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    if configuration.behavior.cancelsOnDisappear {
      sessionCoordinator.cancelAll()
      hideSearchLoading()
      hideSearchSkeleton()
    }
    if configuration.placement == .navigationBar {
      navigationItem.titleView = nil
    }
  }

  // MARK: - Public API

  /// Re-runs the current normalized query (used by error retry and programmatic refresh).
  public func retryCurrentSearch() {
    handleSearchQueryChanged(currentQuery)
  }

  /// Programmatically updates the query; respects ``FKSearchTextUpdateOptions``.
  public func setQuery(_ query: String, options: FKSearchTextUpdateOptions = .withSearchQuery) {
    searchBar.setText(query, options: options)
  }

  /// Override to customize list configuration or cell registration.
  open func makeListViewController() -> FKDiffableTableViewController {
    let list = FKSearchResultsListViewController(configuration: configuration.list)
    list.searchHost = self
    return list
  }

  /// Override to adjust search bar after default callback wiring.
  open func configureSearchBar(_ searchBar: FKSearchBar) {}

  /// Override empty/error copy; return `nil` to use list defaults.
  open func emptyConfiguration(for state: FKListPresentationState) -> FKEmptyStateConfiguration? {
    switch state {
    case .empty:
      var model = FKEmptyStateConfiguration.scenario(configuration.empty.searchNoResultsScenario)
      model.phase = .empty
      if let title = configuration.empty.overridesTitle {
        model.content.title = title
      }
      if let message = configuration.empty.overridesMessage {
        model.content.description = message
      }
      return model
    case .error:
      var model = FKEmptyStateConfiguration.scenario(.loadFailed)
      model.phase = .error
      if let title = configuration.empty.overridesTitle {
        model.content.title = title
      }
      if let message = configuration.empty.overridesMessage {
        model.content.description = message
      }
      return model
    default:
      return nil
    }
  }

  /// Optional hook before a debounced or submitted query runs.
  open func willPerformSearch(query: String) {}

  /// Optional hook after presentation state changes; default forwards delegate/callbacks.
  open func didUpdatePresentationState(_ state: FKSearchPresentationState) {
    if let handler = callbacks.onPresentationStateChanged {
      handler(state)
    } else {
      delegate?.searchViewController(self, stateChanged: state)
    }
  }

  // MARK: - Setup

  private func wireSearchBarCallbacks() {
    searchBar.callbacks.onEditingDidBegin = { [weak self] in
      guard let self else { return }
      if case .idle = self.presentationState {
        self.updatePresentationState(.editing)
      }
    }

    searchBar.callbacks.onSearchQueryChanged = { [weak self] query in
      self?.handleSearchQueryChanged(query)
    }

    searchBar.callbacks.onSubmit = { [weak self] query in
      self?.handleSearchQueryChanged(query)
    }

    searchBar.callbacks.onCancel = { [weak self] in
      self?.handleSearchCancel()
    }

    searchBar.callbacks.onClear = { [weak self] in
      self?.sessionCoordinator.cancelAll()
      self?.hideSearchLoading()
      self?.hideSearchSkeleton()
    }
  }

  private func embedListViewController() {
    addChild(listViewController)
    listViewController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(listViewController.view)
    listViewController.didMove(toParent: self)

    let topAnchor: NSLayoutYAxisAnchor
    switch configuration.placement {
    case .navigationBar, .tableHeader:
      topAnchor = view.safeAreaLayoutGuide.topAnchor
    case .stickyHeader:
      let chrome = FKSearchChromeContainerView(searchBar: searchBar)
      chrome.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(chrome)
      chromeContainer = chrome
      NSLayoutConstraint.activate([
        chrome.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        chrome.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        chrome.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      ])
      topAnchor = chrome.bottomAnchor
    }

    let top = listViewController.view.topAnchor.constraint(equalTo: topAnchor)
    listTopConstraint = top
    NSLayoutConstraint.activate([
      top,
      listViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      listViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      listViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func installSearchPlacement() {
    switch configuration.placement {
    case .navigationBar:
      break
    case .stickyHeader:
      break
    case .tableHeader:
      if !didInstallTableHeader {
        didInstallTableHeader = true
        FKSearchTableHeaderInstaller.install(searchBar: searchBar, in: listViewController.tableView)
      }
    }
  }

  private func refreshNavigationBarSearchPlacementIfNeeded() {
    guard configuration.placement == .navigationBar else { return }
    FKSearchBarNavigationHosting.install(searchBar, in: navigationItem, placeholder: searchBar.placeholder)
  }

  private func applyConfiguration() {
    searchBar.apply(configuration.searchBar)
    listViewController?.configuration = configuration.list
  }

  private func installInitialContentIfNeeded() {
    guard !didInstallInitialContent else { return }
    didInstallInitialContent = true
    switch configuration.mode {
    case .localFilter:
      performLocalFilter(query: "", isEmptyQuery: true)
    case .remote:
      applyRemoteIdleState()
    }
  }

  // MARK: - Search handling

  private func handleSearchQueryChanged(_ query: String) {
    currentQuery = query
    willPerformSearch(query: query)
    let isEmptyQuery = isEffectivelyEmptyQuery(query)

    switch configuration.mode {
    case .localFilter:
      performLocalFilter(query: query, isEmptyQuery: isEmptyQuery)
    case .remote:
      performRemoteSearch(query: query, isEmptyQuery: isEmptyQuery)
    }
  }

  private func handleSearchCancel() {
    sessionCoordinator.cancelAll()
    hideSearchLoading()
    hideSearchSkeleton()
    if configuration.behavior.cancelRestoresBaseline {
      handleSearchQueryChanged("")
    } else {
      updatePresentationState(.idle)
    }
  }

  private func performLocalFilter(query: String, isEmptyQuery: Bool) {
    guard let provider = localFilterProvider else {
      assertMissingProvider(for: .localFilter)
      return
    }

    clearSelectionIfNeeded()

    let snapshot: FKListSnapshot
    if isEmptyQuery {
      listViewController.activeEmptyScenarioOverride = nil
      snapshot = provider.baselineSnapshot
      updatePresentationState(.idle)
    } else {
      snapshot = provider.filteredSnapshot(for: query)
      if snapshot.totalItemCount == 0 {
        listViewController.activeEmptyScenarioOverride = configuration.empty.searchNoResultsScenario
        updatePresentationState(.empty(query: query, scenario: configuration.empty.searchNoResultsScenario))
      } else {
        listViewController.activeEmptyScenarioOverride = nil
        updatePresentationState(.results(query: query, itemCount: snapshot.totalItemCount))
      }
    }

    listViewController.applySnapshot(
      snapshot,
      animatingDifferences: configuration.behavior.animatesSnapshotChanges
    )
  }

  private func performRemoteSearch(query: String, isEmptyQuery: Bool) {
    let token = sessionCoordinator.beginSearch()

    if isEmptyQuery {
      hideSearchLoading()
      hideSearchSkeleton()
      applyRemoteIdleState()
      return
    }

    if configuration.loading.searchBarLoading {
      searchBar.setLoading(true, animated: true)
    }
    if configuration.loading.useSkeleton {
      showSearchSkeleton()
    }
    updatePresentationState(.loading(query: query))

    let task = Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        guard let provider = self.resultsProvider else {
          self.assertMissingProvider(for: .remote)
          return
        }
        let response = try await provider.search(query: query)
        guard self.sessionCoordinator.isCurrent(token), !Task.isCancelled else { return }

        self.hideSearchLoading()
        self.hideSearchSkeleton()
        self.clearSelectionIfNeeded()
        self.applyRemoteResults(query: query, response: response)
      } catch {
        guard self.sessionCoordinator.isCurrent(token), !Task.isCancelled else { return }
        self.hideSearchLoading()
        self.hideSearchSkeleton()
        let mapped = self.mapError(error)
        guard mapped != .cancelled else { return }
        self.presentSearchError(query: query, error: mapped)
      }
    }
    sessionCoordinator.register(task)
  }

  private func applyRemoteResults(query: String, response: FKSearchResultsResponse) {
    let snapshot = response.snapshot
    if snapshot.totalItemCount == 0 {
      let scenario = response.emptyScenario ?? configuration.empty.searchNoResultsScenario
      listViewController.activeEmptyScenarioOverride = scenario
      updatePresentationState(.empty(query: query, scenario: scenario))
    } else {
      listViewController.activeEmptyScenarioOverride = nil
      updatePresentationState(.results(query: query, itemCount: snapshot.totalItemCount))
    }
    listViewController.applySnapshot(
      snapshot,
      animatingDifferences: configuration.behavior.animatesSnapshotChanges
    )
  }

  private func applyRemoteIdleState() {
    if configuration.behavior.showsResultsOnEmptyQuery {
      listViewController.activeEmptyScenarioOverride = configuration.empty.remoteIdleScenario
      let snapshot = remoteIdleSnapshot
      if snapshot.totalItemCount == 0, configuration.empty.remoteIdleScenario == nil {
        listViewController.activeEmptyScenarioOverride = nil
      }
      updatePresentationState(.idle)
      listViewController.applySnapshot(
        snapshot,
        animatingDifferences: configuration.behavior.animatesSnapshotChanges
      )
    } else {
      listViewController.activeEmptyScenarioOverride = configuration.empty.remoteIdleScenario
      updatePresentationState(.idle)
      listViewController.applySnapshot(
        FKListSnapshot(),
        animatingDifferences: configuration.behavior.animatesSnapshotChanges
      )
      if configuration.empty.remoteIdleScenario == nil {
        listViewController.activeEmptyScenarioOverride = nil
      }
    }
  }

  private func presentSearchError(query: String, error: FKSearchError) {
    listViewController.activeEmptyScenarioOverride = .loadFailed
    updatePresentationState(.error(query: query, error: error))
    listViewController.applySnapshot(FKListSnapshot(), animatingDifferences: false)
  }

  // MARK: - Helpers

  private func isEffectivelyEmptyQuery(_ query: String) -> Bool {
    let minimum = configuration.searchBar.debounce.minimumQueryLengthForSearchCallback
    return query.count < minimum
  }

  private func clearSelectionIfNeeded() {
    guard configuration.list.search?.clearsSelectionOnSearch == true else { return }
    listViewController.tableView.indexPathsForSelectedRows?.forEach {
      listViewController.tableView.deselectRow(at: $0, animated: false)
    }
  }

  private func updatePresentationState(_ state: FKSearchPresentationState) {
    presentationState = state
    didUpdatePresentationState(state)
  }

  private func hideSearchLoading() {
    guard configuration.loading.searchBarLoading else { return }
    searchBar.setLoading(false, animated: true)
  }

  private func showSearchSkeleton() {
    guard !isShowingSearchSkeleton else { return }
    isShowingSearchSkeleton = true
    listViewController.view.fk_showSkeleton(over: listViewController.tableView, animated: true)
  }

  private func hideSearchSkeleton() {
    guard isShowingSearchSkeleton else { return }
    isShowingSearchSkeleton = false
    listViewController.view.fk_hideSkeleton(animated: true)
  }

  private func mapError(_ error: Error) -> FKSearchError {
    if error is CancellationError { return .cancelled }
    if let searchError = error as? FKSearchError { return searchError }
    return .providerFailed(error.localizedDescription)
  }

  private func assertMissingProvider(for mode: FKSearchMode) {
    #if DEBUG
    switch mode {
    case .localFilter:
      assertionFailure("FKSearchViewController.localFilterProvider must be set for localFilter mode.")
    case .remote:
      assertionFailure("FKSearchViewController.resultsProvider must be set for remote mode.")
    }
    #endif
  }
}
