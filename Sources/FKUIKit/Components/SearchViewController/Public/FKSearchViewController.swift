import UIKit

/// Composes ``FKSearchBar``, optional custom search/results regions, and ListKit-driven search orchestration.
///
/// Default configuration (``FKSearchPresentationConfiguration/unified``) preserves the v1 single-page
/// search + embedded list experience. Opt in to custom idle/results surfaces via ``configuration/presentation``.
@MainActor
open class FKSearchViewController: UIViewController {
  public var configuration: FKSearchViewControllerConfiguration {
    didSet { applyConfiguration() }
  }

  public private(set) var searchBar: FKSearchBar
  public private(set) var resultsViewController: UIViewController!
  public private(set) var searchContentViewController: UIViewController?
  public private(set) var presentationState: FKSearchPresentationState = .idle

  /// Embedded ListKit child when ``FKSearchResultsPresentationMode/embeddedList`` or results VC is a list subclass.
  public var listViewController: FKDiffableTableViewController? {
    resultsViewController as? FKDiffableTableViewController
  }

  public var callbacks = FKSearchViewControllerCallbacks()
  public weak var delegate: FKSearchViewControllerDelegate?

  /// Required for ``FKSearchMode/localFilter`` when built-in search runs.
  public weak var localFilterProvider: FKSearchLocalFilterProviding?
  /// Required for ``FKSearchMode/remote`` when built-in search runs.
  public weak var resultsProvider: FKSearchResultsProviding?

  /// Snapshot restored when remote query is empty and ``FKSearchBehaviorConfiguration/showsResultsOnEmptyQuery`` is `true`.
  public var remoteIdleSnapshot: FKListSnapshot = FKListSnapshot()

  private let sessionCoordinator = FKSearchSessionCoordinator()
  private var contentContainer: FKSearchContentContainer!
  private var chromeContainer: FKSearchChromeContainerView?
  private var accessoryHostView: UIView?
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

    searchContentViewController = makeSearchContentViewController()
    resultsViewController = makeResultsViewController()
    if let list = listViewController {
      list.delegate = self
      if let resultsList = list as? FKSearchResultsListViewController {
        resultsList.searchHost = self
      }
    }

    configureSearchBar(searchBar)
    wireSearchBarCallbacks()
    installChromeAndContent()
    installSearchPlacement()
    applyConfiguration()
    updateContentVisibility(isEmptyQuery: true)
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
    if configuration.placement == .tableHeader, let tableView = listViewController?.tableView {
      FKSearchTableHeaderInstaller.refresh(tableView)
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

  /// Override to customize the embedded ListKit table used for unified or list-backed results.
  open func makeListViewController() -> FKDiffableTableViewController {
    let list = FKSearchResultsListViewController(configuration: configuration.list)
    list.searchHost = self
    return list
  }

  /// Override to supply the results child. Default forwards to ``makeListViewController()``.
  open func makeResultsViewController() -> UIViewController {
    makeListViewController()
  }

  /// Override to supply a custom search-page body shown when the query is empty.
  /// Return `nil` when ``FKSearchIdleContentPresentation/customViewController`` is not used.
  open func makeSearchContentViewController() -> UIViewController? {
    nil
  }

  /// Optional view placed below ``searchBar`` (filter chips, hints). Default: `nil`.
  open func makeSearchAccessoryView() -> UIView? {
    nil
  }

  /// Override to adjust search bar after default callback wiring.
  open func configureSearchBar(_ searchBar: FKSearchBar) {}

  /// Override empty/error copy for embedded list results; return `nil` to use list defaults.
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

  private func installChromeAndContent() {
    let topAnchor = installSearchChrome()
    contentContainer = FKSearchContentContainer(
      resultsViewController: resultsViewController,
      searchContentViewController: searchContentViewController
    )
    contentContainer.embed(in: self, below: topAnchor, in: view)
  }

  private func installSearchChrome() -> NSLayoutYAxisAnchor {
    let accessory = makeSearchAccessoryView()
    switch configuration.placement {
    case .navigationBar, .tableHeader:
      if let accessory {
        let host = UIView()
        host.translatesAutoresizingMaskIntoConstraints = false
        accessory.translatesAutoresizingMaskIntoConstraints = false
        host.addSubview(accessory)
        view.addSubview(host)
        NSLayoutConstraint.activate([
          host.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
          host.leadingAnchor.constraint(equalTo: view.leadingAnchor),
          host.trailingAnchor.constraint(equalTo: view.trailingAnchor),
          accessory.topAnchor.constraint(equalTo: host.topAnchor, constant: 8),
          accessory.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 16),
          accessory.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -16),
          accessory.bottomAnchor.constraint(equalTo: host.bottomAnchor, constant: -8),
        ])
        accessoryHostView = host
        return host.bottomAnchor
      }
      return view.safeAreaLayoutGuide.topAnchor

    case .stickyHeader:
      let chrome = FKSearchChromeContainerView(searchBar: searchBar, accessoryView: accessory)
      chrome.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(chrome)
      chromeContainer = chrome
      NSLayoutConstraint.activate([
        chrome.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        chrome.leadingAnchor.constraint(equalTo: view.leadingAnchor),
        chrome.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      ])
      return chrome.bottomAnchor
    }
  }

  private func installSearchPlacement() {
    switch configuration.placement {
    case .navigationBar, .stickyHeader:
      break
    case .tableHeader:
      guard !didInstallTableHeader, let tableView = listViewController?.tableView else { return }
      didInstallTableHeader = true
      FKSearchTableHeaderInstaller.install(searchBar: searchBar, in: tableView)
    }
  }

  private func refreshNavigationBarSearchPlacementIfNeeded() {
    guard configuration.placement == .navigationBar else { return }
    FKSearchBarNavigationHosting.install(searchBar, in: navigationItem, placeholder: searchBar.placeholder)
  }

  private func applyConfiguration() {
    searchBar.apply(configuration.searchBar)
    listViewController?.configuration = configuration.list
    chromeContainer?.setAccessoryView(makeSearchAccessoryView())
  }

  private func installInitialContentIfNeeded() {
    guard !didInstallInitialContent else { return }
    didInstallInitialContent = true
    handleSearchQueryChanged("")
  }

  // MARK: - Search handling

  private func handleSearchQueryChanged(_ query: String) {
    currentQuery = query
    willPerformSearch(query: query)
    let isEmptyQuery = isEffectivelyEmptyQuery(query)

    if isEmptyQuery {
      sessionCoordinator.cancelAll()
      hideSearchLoading()
      hideSearchSkeleton()
      applyIdleState()
      return
    }

    let dispatch = resolveSearchQueryDispatch(for: query)
    if dispatch == .handledByHost {
      notifyHostSearchRequested(query: query)
      updatePresentationState(.loading(query: query))
      updateContentVisibility(isEmptyQuery: false)
      hideSearchLoading()
      hideSearchSkeleton()
      return
    }

    updateContentVisibility(isEmptyQuery: false)

    switch configuration.mode {
    case .localFilter:
      performLocalFilter(query: query)
    case .remote:
      performRemoteSearch(query: query)
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
      updateContentVisibility(isEmptyQuery: true)
    }
  }

  private func applyIdleState() {
    switch configuration.mode {
    case .localFilter:
      if usesBuiltInListForIdleSnapshot {
        performLocalFilter(query: "", isEmptyQuery: true)
      } else {
        updatePresentationState(.idle)
        applyResultsUpdate(.idle)
      }
    case .remote:
      applyRemoteIdleState()
    }
    updateContentVisibility(isEmptyQuery: true)
  }

  private func performLocalFilter(query: String, isEmptyQuery: Bool = false) {
    guard let provider = localFilterProvider else {
      assertMissingProvider(for: .localFilter)
      return
    }

    clearSelectionIfNeeded()

    let snapshot: FKListSnapshot
    if isEmptyQuery {
      snapshot = provider.baselineSnapshot
      updatePresentationState(.idle)
      applyResultsUpdate(.idle)
      applySnapshotToResults(snapshot, query: query, animatingDifferences: configuration.behavior.animatesSnapshotChanges)
      listViewController?.activeEmptyScenarioOverride = nil
    } else {
      snapshot = provider.filteredSnapshot(for: query)
      if snapshot.totalItemCount == 0 {
        let scenario = configuration.empty.searchNoResultsScenario
        updatePresentationState(.empty(query: query, scenario: scenario))
        applyResultsUpdate(.empty(query: query, scenario: scenario))
        listViewController?.activeEmptyScenarioOverride = scenario
      } else {
        updatePresentationState(.results(query: query, itemCount: snapshot.totalItemCount))
        applyResultsUpdate(.results(query: query, snapshot: snapshot))
        listViewController?.activeEmptyScenarioOverride = nil
      }
      applySnapshotToResults(snapshot, query: query, animatingDifferences: configuration.behavior.animatesSnapshotChanges)
    }
  }

  private func performRemoteSearch(query: String) {
    let token = sessionCoordinator.beginSearch()

    if configuration.loading.searchBarLoading {
      searchBar.setLoading(true, animated: true)
    }
    if configuration.loading.useSkeleton {
      showSearchSkeleton()
    }
    updatePresentationState(.loading(query: query))
    applyResultsUpdate(.loading(query: query))

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
      listViewController?.activeEmptyScenarioOverride = scenario
      updatePresentationState(.empty(query: query, scenario: scenario))
      applyResultsUpdate(.empty(query: query, scenario: scenario))
    } else {
      listViewController?.activeEmptyScenarioOverride = nil
      updatePresentationState(.results(query: query, itemCount: snapshot.totalItemCount))
      applyResultsUpdate(.results(query: query, snapshot: snapshot))
    }
    applySnapshotToResults(snapshot, query: query, animatingDifferences: configuration.behavior.animatesSnapshotChanges)
  }

  private func applyRemoteIdleState() {
    updatePresentationState(.idle)
    applyResultsUpdate(.idle)

    guard usesBuiltInListForIdleSnapshot else { return }

    if configuration.behavior.showsResultsOnEmptyQuery {
      listViewController?.activeEmptyScenarioOverride = configuration.empty.remoteIdleScenario
      let snapshot = remoteIdleSnapshot
      if snapshot.totalItemCount == 0, configuration.empty.remoteIdleScenario == nil {
        listViewController?.activeEmptyScenarioOverride = nil
      }
      applySnapshotToResults(snapshot, query: "", animatingDifferences: configuration.behavior.animatesSnapshotChanges)
    } else {
      listViewController?.activeEmptyScenarioOverride = configuration.empty.remoteIdleScenario
      applySnapshotToResults(FKListSnapshot(), query: "", animatingDifferences: configuration.behavior.animatesSnapshotChanges)
      if configuration.empty.remoteIdleScenario == nil {
        listViewController?.activeEmptyScenarioOverride = nil
      }
    }
  }

  private func presentSearchError(query: String, error: FKSearchError) {
    listViewController?.activeEmptyScenarioOverride = .loadFailed
    updatePresentationState(.error(query: query, error: error))
    applyResultsUpdate(.error(query: query, error: error))
    applySnapshotToResults(FKListSnapshot(), query: query, animatingDifferences: false)
  }

  // MARK: - Results routing

  private var usesBuiltInListForIdleSnapshot: Bool {
    switch configuration.presentation.idleContent {
    case .listSnapshot:
      return configuration.presentation.resultsMode != .hostHandled
    case .customViewController, .none:
      return false
    }
  }

  private func resolveSearchQueryDispatch(for query: String) -> FKSearchQueryDispatch {
    if configuration.presentation.resultsMode == .hostHandled {
      return .handledByHost
    }
    if let handler = callbacks.onSearchQueryDispatch {
      return handler(query, self)
    }
    return delegate?.searchViewController(self, searchQueryDispatchFor: query) ?? .performBuiltIn
  }

  private func notifyHostSearchRequested(query: String) {
    if let handler = callbacks.onHostSearchRequested {
      handler(query, self)
    } else {
      delegate?.searchViewController(self, hostSearchRequested: query)
    }
  }

  private func applyResultsUpdate(_ update: FKSearchResultsPresentationUpdate) {
    if let display = resultsViewController as? FKSearchResultsDisplaying {
      display.applySearchResultsUpdate(update, from: self)
    }
  }

  private func applySnapshotToResults(
    _ snapshot: FKListSnapshot,
    query: String,
    animatingDifferences: Bool
  ) {
    if let list = listViewController {
      list.applySnapshot(snapshot, animatingDifferences: animatingDifferences)
      return
    }
    if snapshot.totalItemCount == 0 {
      if case .empty = presentationState {
        // custom display handles via applyResultsUpdate
      }
    } else {
      applyResultsUpdate(.results(query: query, snapshot: snapshot))
    }
  }

  private func updateContentVisibility(isEmptyQuery: Bool) {
    let presentation = configuration.presentation

    if isEmptyQuery {
      switch presentation.idleContent {
      case .customViewController where searchContentViewController != nil:
        contentContainer.setVisibleSurface(.searchContent)
      case .listSnapshot where usesBuiltInListForIdleSnapshot:
        contentContainer.setVisibleSurface(.results)
      case .none:
        contentContainer.setVisibleSurface(.none)
      default:
        contentContainer.setVisibleSurface(.results)
      }
      return
    }

    if presentation.resultsMode == .hostHandled {
      if presentation.idleContent == .customViewController, searchContentViewController != nil {
        contentContainer.setVisibleSurface(.searchContent)
      } else {
        contentContainer.setVisibleSurface(.none)
      }
      return
    }

    contentContainer.setVisibleSurface(.results)
  }

  // MARK: - Helpers

  private func isEffectivelyEmptyQuery(_ query: String) -> Bool {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return true }
    let minimum = configuration.searchBar.debounce.minimumQueryLengthForSearchCallback
    return trimmed.count < minimum
  }

  private func clearSelectionIfNeeded() {
    guard configuration.list.search?.clearsSelectionOnSearch == true else { return }
    listViewController?.tableView.indexPathsForSelectedRows?.forEach {
      listViewController?.tableView.deselectRow(at: $0, animated: false)
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
    guard let hostView = resultsViewController.view else { return }
    guard let scrollView = listViewController?.tableView ?? resultsViewController.view as? UIScrollView else {
      return
    }
    isShowingSearchSkeleton = true
    hostView.fk_showSkeleton(over: scrollView, animated: true)
  }

  private func hideSearchSkeleton() {
    guard isShowingSearchSkeleton else { return }
    isShowingSearchSkeleton = false
    resultsViewController.view?.fk_hideSkeleton(animated: true)
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
