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
  /// Query string last processed by the search orchestrator (as emitted by ``FKSearchBar``).
  public private(set) var currentQuery = ""

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
    }
    if let resultsList = resultsViewController as? FKSearchResultsListViewController {
      resultsList.searchHost = self
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

  /// Re-runs the current query (used by error retry and programmatic refresh).
  public func retryCurrentSearch() {
    let trigger: SearchQueryTrigger = configuration.presentation.resultsMode == .hostHandled ? .submit : .debouncedChange
    handleSearchQueryChanged(currentQuery, trigger: trigger)
  }

  /// Programmatically updates the query; respects ``FKSearchTextUpdateOptions``.
  ///
  /// When ``FKSearchTextUpdateOptions/triggerSearchQueryChanged`` is `true`, host-handled presentation
  /// notifies the host immediately (same as Return / submit).
  public func setQuery(_ query: String, options: FKSearchTextUpdateOptions = .withSearchQuery) {
    if options.triggerSearchQueryChanged {
      searchBar.setText(query, options: .silent)
      handleSearchQueryChanged(query, trigger: .programmatic)
    } else {
      searchBar.setText(query, options: options)
    }
  }

  /// Override to customize the embedded ListKit table used for unified or list-backed results.
  open func makeListViewController() -> FKDiffableTableViewController {
    FKSearchResultsListViewController(configuration: configuration.list)
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
      return makeSearchEmptyStateConfiguration(
        scenario: configuration.empty.searchNoResultsScenario,
        phase: .empty
      )
    case .error:
      return makeSearchEmptyStateConfiguration(scenario: .loadFailed, phase: .error)
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
      self?.handleSearchQueryChanged(query, trigger: .debouncedChange)
    }

    searchBar.callbacks.onSubmit = { [weak self] query in
      self?.handleSearchQueryChanged(query, trigger: .submit)
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
    switch configuration.placement {
    case .stickyFooter:
      installStickyFooterChromeAndContent()
    default:
      let topAnchor = installSearchChrome()
      contentContainer = FKSearchContentContainer(
        resultsViewController: resultsViewController,
        searchContentViewController: searchContentViewController
      )
      contentContainer.embed(in: self, below: topAnchor, in: view)
    }
  }

  private func installStickyFooterChromeAndContent() {
    let accessory = makeSearchAccessoryView()
    let chrome = FKSearchChromeContainerView(searchBar: searchBar, accessoryView: accessory)
    chrome.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(chrome)
    chromeContainer = chrome

    contentContainer = FKSearchContentContainer(
      resultsViewController: resultsViewController,
      searchContentViewController: searchContentViewController
    )
    contentContainer.embed(
      in: self,
      topAnchor: view.safeAreaLayoutGuide.topAnchor,
      bottomAnchor: chrome.topAnchor,
      in: view
    )

    installStickyFooterChromeBottomConstraints(for: chrome)
  }

  private func installStickyFooterChromeBottomConstraints(for chrome: UIView) {
    if #available(iOS 17.0, *) {
      view.keyboardLayoutGuide.usesBottomSafeArea = true
    }

    NSLayoutConstraint.activate([
      chrome.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      chrome.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      chrome.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
    ])

    let followKeyboard = chrome.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
    followKeyboard.priority = UILayoutPriority(999)
    followKeyboard.isActive = true

    let restingBottom = chrome.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    restingBottom.priority = UILayoutPriority(998)
    restingBottom.isActive = true
  }

  /// Empty/error overlays sit above sticky-footer chrome; keyboard tracking stays on chrome placement.
  private func applyStickyFooterEmptyStatePresentationIfNeeded(_ model: inout FKEmptyStateConfiguration) {
    guard configuration.placement == .stickyFooter else { return }
    model.presentation.adjustsPositionForKeyboard = false
  }

  private func makeSearchEmptyStateConfiguration(
    scenario: FKEmptyStateScenario,
    phase: FKEmptyStatePhase
  ) -> FKEmptyStateConfiguration {
    var model = FKEmptyStateConfiguration.scenario(scenario)
    model.phase = phase
    if let title = configuration.empty.overridesTitle {
      model.content.title = title
    }
    if let message = configuration.empty.overridesMessage {
      model.content.description = message
    }
    applyStickyFooterEmptyStatePresentationIfNeeded(&model)
    return model
  }

  /// Lazy-mounted results/search content is added after chrome; keep footer chrome above content.
  private func bringStickyFooterChromeToFrontIfNeeded() {
    guard configuration.placement == .stickyFooter, let chromeContainer else { return }
    view.bringSubviewToFront(chromeContainer)
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

    case .stickyFooter:
      fatalError("stickyFooter placement uses installStickyFooterChromeAndContent(), not installSearchChrome().")
    }
  }

  private func installSearchPlacement() {
    switch configuration.placement {
    case .navigationBar, .stickyHeader, .stickyFooter:
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
    if configuration.placement == .stickyFooter {
      listViewController?.tableView.contentInsetAdjustmentBehavior = .never
    }
  }

  private func installInitialContentIfNeeded() {
    guard !didInstallInitialContent else { return }
    didInstallInitialContent = true
    handleSearchQueryChanged("")
  }

  // MARK: - Search handling

  private enum SearchQueryTrigger {
    case debouncedChange
    case submit
    case programmatic
  }

  private func handleSearchQueryChanged(_ query: String, trigger: SearchQueryTrigger = .debouncedChange) {
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

    if configuration.presentation.resultsMode == .hostHandled {
      handleHostHandledQuery(query, trigger: trigger)
      return
    }

    let dispatch = resolveSearchQueryDispatch(for: query)
    if dispatch == .handledByHost {
      notifyHostSearchRequested(query: query)
      updatePresentationState(.editing)
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

  private func handleHostHandledQuery(_ query: String, trigger: SearchQueryTrigger) {
    updateContentVisibility(isEmptyQuery: false)
    sessionCoordinator.cancelAll()
    hideSearchLoading()
    hideSearchSkeleton()

    guard trigger == .submit || trigger == .programmatic else {
      updatePresentationState(.editing)
      return
    }

    notifyHostSearchRequested(query: query)
    updatePresentationState(.editing)
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
      applySnapshotToResults(snapshot, animatingDifferences: configuration.behavior.animatesSnapshotChanges)
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
      applySnapshotToResults(snapshot, animatingDifferences: configuration.behavior.animatesSnapshotChanges)
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
    applySnapshotToResults(snapshot, animatingDifferences: configuration.behavior.animatesSnapshotChanges)
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
      applySnapshotToResults(snapshot, animatingDifferences: configuration.behavior.animatesSnapshotChanges)
    } else {
      listViewController?.activeEmptyScenarioOverride = configuration.empty.remoteIdleScenario
      applySnapshotToResults(FKListSnapshot(), animatingDifferences: configuration.behavior.animatesSnapshotChanges)
      if configuration.empty.remoteIdleScenario == nil {
        listViewController?.activeEmptyScenarioOverride = nil
      }
    }
  }

  private func presentSearchError(query: String, error: FKSearchError) {
    listViewController?.activeEmptyScenarioOverride = .loadFailed
    updatePresentationState(.error(query: query, error: error))
    applyResultsUpdate(.error(query: query, error: error))
    applySnapshotToResults(FKListSnapshot(), animatingDifferences: false)
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

  private func applySnapshotToResults(_ snapshot: FKListSnapshot, animatingDifferences: Bool) {
    listViewController?.applySnapshot(snapshot, animatingDifferences: animatingDifferences)
  }

  private func updateContentVisibility(isEmptyQuery: Bool) {
    defer { bringStickyFooterChromeToFrontIfNeeded() }

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
