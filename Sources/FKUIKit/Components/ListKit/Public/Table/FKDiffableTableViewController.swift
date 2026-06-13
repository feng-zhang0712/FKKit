import FKCoreKit
import UIKit

/// Diffable table list base controller integrating refresh, pagination, empty state, and skeleton.
@MainActor
open class FKDiffableTableViewController: UIViewController {
  public let tableView: UITableView
  public var configuration: FKListConfiguration {
    didSet { applyConfiguration() }
  }
  public var pagination = FKRefreshPagination()
  public private(set) var presentationState: FKListPresentationState = .initialLoading
  public private(set) var currentSnapshot = FKListSnapshot()

  public weak var delegate: FKListDelegate?
  public weak var dataProvider: FKListDataProviding?

  public let swipeActionHandlerRegistry = FKListSwipeActionHandlerRegistry()
  public let switchHandlerRegistry = FKListSwitchHandlerRegistry()
  public let checkboxHandlerRegistry = FKListCheckboxHandlerRegistry()

  /// Optional per-item row height when ``FKListRowHeightPolicy`` is insufficient.
  public var rowHeightProvider: ((FKListItem) -> CGFloat)?

  /// Selection callbacks keyed by item id.
  public var didSelectItem: ((FKListItemID) -> Void)?
  public var didDeselectItem: ((FKListItemID) -> Void)?

  /// Overrides ``FKListEmptyConfiguration/scenario`` when the next snapshot apply yields zero items.
  public var activeEmptyScenarioOverride: FKEmptyStateScenario?

  /// Invoked by ``reloadInitialContent()`` when ``dataProvider`` is nil.
  public var hostReloadHandler: (@MainActor (FKDiffableTableViewController) async throws -> Void)?

  private var dataSource: UITableViewDiffableDataSource<FKListSectionID, FKListItemID>!
  private let loadCoordinator = FKListLoadCoordinator()
  private let presentationCoordinator = FKListPresentationCoordinator()
  private let itemStore = FKListItemStore()
  private let cellRegistry = FKListTableCellRegistry()
  private var sectionViewProviders: [String: @MainActor () -> UIView] = [:]
  private var needsInitialSkeletonPresentation = false

  public init(configuration: FKListConfiguration = FKListDefaults.defaultConfiguration, style: UITableView.Style = .plain) {
    self.configuration = configuration
    self.tableView = UITableView(frame: .zero, style: style)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle

  open override func viewDidLoad() {
    super.viewDidLoad()
    setupTableView()
    setupDataSource()
    registerPresetCells()
    registerAdditionalCells(in: tableView)
    applyConfiguration()
    installRefreshControlsIfNeeded()
    if configuration.loading.usesSkeletonForInitialLoad {
      transitionPresentationState(to: .initialLoading)
      presentInitialSkeletonIfNeeded()
    }
    if dataProvider != nil {
      reloadInitialContent()
    }
  }

  open override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    if configuration.loading.usesSkeletonForInitialLoad, case .initialLoading = presentationState {
      presentInitialSkeletonIfNeeded()
    }
  }

  open override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if needsInitialSkeletonPresentation {
      presentInitialSkeletonIfNeeded()
    } else if case .initialLoading = presentationState, configuration.loading.usesSkeletonForInitialLoad {
      view.fk_bringSkeletonOverlayToFrontIfNeeded()
    }
    syncEmptyStateOverlayIfNeeded()
  }

  // MARK: - Public API

  /// Applies a full snapshot and updates presentation state.
  open func applySnapshot(
    _ snapshot: FKListSnapshot,
    animatingDifferences: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    assertDuplicateItemIDsIfNeeded(snapshot)
    commitSnapshot(
      snapshot,
      animatingDifferences: animatingDifferences,
      reloadIDs: snapshot.itemIDsWithChangedContent(comparedTo: currentSnapshot),
      reloadSectionIDs: [],
      completion: completion
    )
    updatePresentationAfterSnapshotApply()
  }

  /// Applies an incremental snapshot mutation.
  open func applyMutation(
    _ mutation: FKListSnapshotMutation,
    animatingDifferences: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    var working = currentSnapshot
    var reloadIDs: [FKListItemID] = []
    var reloadSectionIDs: [FKListSectionID] = []
    switch mutation {
    case .reloadItems(let ids):
      reloadIDs = ids
      FKListSnapshotApplier.apply(mutation, to: &working)
    case .reloadSections(let sectionIDs):
      reloadSectionIDs = sectionIDs
      FKListSnapshotApplier.apply(mutation, to: &working)
    default:
      FKListSnapshotApplier.apply(mutation, to: &working)
    }
    assertDuplicateItemIDsIfNeeded(working)
    let contentChangedIDs = working.itemIDsWithChangedContent(comparedTo: currentSnapshot)
    let effectiveReloadIDs = Array(Set(reloadIDs + contentChangedIDs))
    commitSnapshot(
      working,
      animatingDifferences: animatingDifferences,
      reloadIDs: effectiveReloadIDs,
      reloadSectionIDs: reloadSectionIDs,
      completion: completion
    )
    updatePresentationAfterSnapshotApply()
  }

  /// Stores a custom cell payload for `id`.
  public func setPayload(_ payload: FKListItemPayload, for id: FKListItemID) {
    itemStore.setPayload(payload, for: id)
  }

  /// Registers a custom configurable cell type.
  open func register<Cell: FKListTableCellConfigurable>(
    _ cellType: Cell.Type,
    forPayloadType payloadType: Cell.Item.Type
  ) {
    cellRegistry.register(cellType, forPayloadType: payloadType, in: tableView)
  }

  /// Registers a custom section header/footer provider.
  public func registerSectionViewProvider(
    id: String,
    provider: @escaping @MainActor () -> UIView
  ) {
    sectionViewProviders[id] = provider
  }

  /// Host-driven initial load entry point.
  open func loadInitialContent(
    handler: @escaping @MainActor (FKDiffableTableViewController) async throws -> Void
  ) {
    let token = loadCoordinator.begin(.initial)
    transitionPresentationState(to: .initialLoading)
    if configuration.loading.usesSkeletonForInitialLoad {
      presentInitialSkeletonIfNeeded()
    }
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        try await handler(self)
        guard self.loadCoordinator.isCurrent(token: token, for: .initial) else { return }
      } catch {
        guard self.loadCoordinator.isCurrent(token: token, for: .initial) else { return }
        self.handleLoadFailure(error, operation: .initial)
      }
    }
  }

  /// Reloads content from ``dataProvider`` or ``hostReloadHandler``.
  open func reloadInitialContent() {
    guard let dataProvider else {
      if let hostReloadHandler {
        loadInitialContent(handler: hostReloadHandler)
      }
      return
    }
    let token = loadCoordinator.begin(.initial)
    transitionPresentationState(to: .initialLoading)
    if configuration.loading.usesSkeletonForInitialLoad {
      presentInitialSkeletonIfNeeded()
    }
    Task { @MainActor [weak self] in
      guard let self else { return }
      do {
        let result = try await dataProvider.fetchInitial(page: self.pagination.page)
        guard self.loadCoordinator.isCurrent(token: token, for: .initial) else { return }
        self.loadCoordinator.updateHasMorePages(result.hasMorePages)
        self.applySnapshot(result.snapshot, animatingDifferences: false)
      } catch {
        guard self.loadCoordinator.isCurrent(token: token, for: .initial) else { return }
        self.handleLoadFailure(error, operation: .initial)
      }
    }
  }

  /// Programmatically selects a row by item id.
  public func selectItem(withID id: FKListItemID, animated: Bool = true, scrollPosition: UITableView.ScrollPosition = .none) {
    guard let indexPath = indexPath(for: id) else { return }
    tableView.selectRow(at: indexPath, animated: animated, scrollPosition: scrollPosition)
  }

  /// Programmatically deselects a row by item id.
  public func deselectItem(withID id: FKListItemID, animated: Bool = true) {
    guard let indexPath = indexPath(for: id) else { return }
    tableView.deselectRow(at: indexPath, animated: animated)
  }

  /// Applies ``FKListSelectionConfiguration`` to the table view after nested config mutation.
  public func applySelectionConfiguration() {
    switch configuration.selection.mode {
    case .none:
      tableView.allowsSelection = false
      tableView.allowsMultipleSelection = false
    case .single:
      tableView.allowsSelection = true
      tableView.allowsMultipleSelection = false
    case .multiple:
      tableView.allowsSelection = true
      tableView.allowsMultipleSelection = true
    }
  }

  // MARK: - Subclass hooks

  /// Override to customize preset cell binding after default configuration.
  open func configurePresetCell(
    _ cell: FKListPresetTableCell,
    at indexPath: IndexPath,
    with item: FKListItem
  ) {}

  /// Override to register host custom cells.
  open func registerAdditionalCells(in tableView: UITableView) {}

  /// Override to customize empty/error copy.
  open func makeEmptyStateConfiguration(for state: FKListPresentationState) -> FKEmptyStateConfiguration? {
    switch state {
    case .empty:
      return presentationCoordinator.emptyConfiguration(
        for: configuration,
        scenario: configuration.empty.scenario
      )
    case .error(let presentation):
      return presentationCoordinator.errorConfiguration(for: configuration, presentation: presentation)
    default:
      return nil
    }
  }

  // MARK: - Setup

  private func setupTableView() {
    view.backgroundColor = .systemBackground
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.delegate = self
    tableView.backgroundColor = .systemBackground
    tableView.sectionHeaderTopPadding = configuration.layout.sectionHeaderTopPadding
    view.addSubview(tableView)
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func setupDataSource() {
    dataSource = UITableViewDiffableDataSource<FKListSectionID, FKListItemID>(tableView: tableView) {
      [weak self] tableView, indexPath, itemID in
      guard let self else { return UITableViewCell() }
      return self.dequeueConfiguredCell(tableView: tableView, indexPath: indexPath, itemID: itemID)
    }
    dataSource.defaultRowAnimation = .fade
  }

  private func registerPresetCells() {
    tableView.register(FKListPresetTableCell.self, forCellReuseIdentifier: FKListPresetTableCell.reuseIdentifier)
    tableView.register(FKListSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: FKListSectionHeaderView.reuseIdentifier)
    tableView.register(FKListSectionFooterView.self, forHeaderFooterViewReuseIdentifier: FKListSectionFooterView.reuseIdentifier)
  }

  private func applyConfiguration() {
    let insets = configuration.layout.contentInsets
    tableView.contentInset = insets
    tableView.scrollIndicatorInsets = insets
    if configuration.layout.pinsSectionHeaders {
      tableView.sectionHeaderTopPadding = configuration.layout.sectionHeaderTopPadding
    } else {
      tableView.sectionHeaderTopPadding = 0
    }
    tableView.estimatedSectionHeaderHeight = UITableView.automaticDimension
    tableView.estimatedSectionFooterHeight = UITableView.automaticDimension
    switch configuration.layout.separatorMode {
    case .system:
      tableView.separatorStyle = .singleLine
    case .fkDivider, .none:
      tableView.separatorStyle = .none
    }
    switch configuration.layout.rowHeightPolicy {
    case .automatic:
      tableView.rowHeight = UITableView.automaticDimension
      tableView.estimatedRowHeight = 52
    case .fixed(let height):
      tableView.rowHeight = height
      tableView.estimatedRowHeight = height
    }
    applySelectionConfiguration()
    tableView.prefetchDataSource = configuration.prefetch.isEnabled ? self : nil
  }

  private func installRefreshControlsIfNeeded() {
    if configuration.refresh.isPullToRefreshEnabled {
      tableView.fk_addPullToRefresh(contextAsyncAction: { [weak self] context in
        await self?.handlePullToRefresh(context: context)
      })
    }
    if configuration.refresh.isLoadMoreEnabled {
      tableView.fk_addLoadMore(
        configuration: configuration.refresh.loadMoreRefreshConfiguration(),
        contextAsyncAction: { [weak self] context in
          await self?.handleLoadMore(context: context)
        }
      )
    }
  }

  // MARK: - Data source helpers

  private func commitSnapshot(
    _ snapshot: FKListSnapshot,
    animatingDifferences: Bool,
    reloadIDs: [FKListItemID],
    reloadSectionIDs: [FKListSectionID],
    completion: (() -> Void)?
  ) {
    currentSnapshot = snapshot
    itemStore.prune(keeping: Set(snapshot.sections.flatMap { $0.items.map(\.id) }))
    applyDiffableSnapshot(
      from: snapshot,
      animatingDifferences: animatingDifferences,
      reloadIDs: reloadIDs,
      reloadSectionIDs: reloadSectionIDs,
      completion: completion
    )
  }

  private func replaceSnapshotWithoutPresentationUpdate(
    _ snapshot: FKListSnapshot,
    animatingDifferences: Bool = false
  ) {
    assertDuplicateItemIDsIfNeeded(snapshot)
    commitSnapshot(
      snapshot,
      animatingDifferences: animatingDifferences,
      reloadIDs: snapshot.itemIDsWithChangedContent(comparedTo: currentSnapshot),
      reloadSectionIDs: [],
      completion: nil
    )
  }

  private func applyDiffableSnapshot(
    from snapshot: FKListSnapshot,
    animatingDifferences: Bool,
    reloadIDs: [FKListItemID],
    reloadSectionIDs: [FKListSectionID],
    completion: (() -> Void)?
  ) {
    let preservedSelection = configuration.selection.preservesSelectionOnUpdates
      ? tableView.indexPathsForSelectedRows?.compactMap { dataSource.itemIdentifier(for: $0) } ?? []
      : []
    var diffable = NSDiffableDataSourceSnapshot<FKListSectionID, FKListItemID>()
    for section in snapshot.sections {
      diffable.appendSections([section.id])
      diffable.appendItems(section.items.map(\.id), toSection: section.id)
    }
    if !reloadIDs.isEmpty {
      diffable.reloadItems(reloadIDs)
    }
    if !reloadSectionIDs.isEmpty {
      diffable.reloadSections(reloadSectionIDs)
    }
    dataSource.apply(diffable, animatingDifferences: animatingDifferences) { [weak self] in
      guard let self else {
        completion?()
        return
      }
      for itemID in preservedSelection {
        self.selectItem(withID: itemID, animated: false)
      }
      completion?()
    }
  }

  private func dequeueConfiguredCell(
    tableView: UITableView,
    indexPath: IndexPath,
    itemID: FKListItemID
  ) -> UITableViewCell {
    guard let item = currentSnapshot.item(withID: itemID) else {
      return UITableViewCell()
    }
    switch item.kind {
    case .preset(let preset):
      let cell = tableView.dequeueReusableCell(
        withIdentifier: FKListPresetTableCell.reuseIdentifier,
        for: indexPath
      ) as! FKListPresetTableCell
      let context = FKListPresetCellContext(
        itemID: item.id,
        preset: preset,
        metadata: item.metadata,
        appearance: configuration.appearance,
        separatorMode: configuration.layout.separatorMode,
        switchHandlerRegistry: switchHandlerRegistry,
        checkboxHandlerRegistry: checkboxHandlerRegistry
      )
      cell.configure(with: context)
      configurePresetCell(cell, at: indexPath, with: item)
      return cell

    case .custom(let custom):
      guard let entry = cellRegistry.entry(for: custom.cellTypeIdentifier),
            let payload = itemStore.payload(for: item.id) else {
        return UITableViewCell()
      }
      let cell = tableView.dequeueReusableCell(withIdentifier: entry.reuseIdentifier, for: indexPath)
      entry.configure(cell, payload)
      return cell
    }
  }

  private func indexPath(for itemID: FKListItemID) -> IndexPath? {
    for (sectionIndex, section) in currentSnapshot.sections.enumerated() {
      if let row = section.items.firstIndex(where: { $0.id == itemID }) {
        return IndexPath(row: row, section: sectionIndex)
      }
    }
    return nil
  }

  // MARK: - Presentation

  private func presentInitialSkeletonIfNeeded() {
    guard configuration.loading.usesSkeletonForInitialLoad else {
      needsInitialSkeletonPresentation = false
      return
    }
    guard case .initialLoading = presentationState else {
      needsInitialSkeletonPresentation = false
      return
    }
    guard view.bounds.width > 0, view.bounds.height > 0 else {
      needsInitialSkeletonPresentation = true
      return
    }
    needsInitialSkeletonPresentation = false
    presentationCoordinator.showSkeleton(
      on: tableView,
      policy: configuration.loading.skeletonPolicy,
      overlayHost: view
    )
    view.fk_bringSkeletonOverlayToFrontIfNeeded()
  }

  private func syncEmptyStateOverlayIfNeeded() {
    let policy = configuration.layout.emptyPresentationPolicy
    if currentSnapshot.totalItemCount > 0 {
      guard tableView.fk_emptyStateView != nil else { return }
      presentationCoordinator.hideEmptyState(
        on: tableView,
        hostView: view,
        policy: policy,
        animatesPresentation: false
      )
      return
    }
    guard case .empty = presentationState else { return }
    tableView.fk_refreshEmptyStateAutomatically { [weak self] action in
      if action.kind == .primary { self?.reloadInitialContent() }
    }
  }

  private func updatePresentationAfterSnapshotApply() {
    needsInitialSkeletonPresentation = false
    presentationCoordinator.hideSkeleton(
      on: tableView,
      policy: configuration.loading.skeletonPolicy,
      overlayHost: view
    )
    let count = currentSnapshot.totalItemCount
    if count == 0 {
      let scenario = activeEmptyScenarioOverride ?? configuration.empty.scenario
      let emptyConfig = makeEmptyStateConfiguration(for: .empty)
        ?? presentationCoordinator.emptyConfiguration(for: configuration, scenario: scenario)
      transitionPresentationState(to: .empty)
      presentationCoordinator.applyEmptyState(
        on: tableView,
        configuration: emptyConfig,
        policy: configuration.layout.emptyPresentationPolicy,
        hostView: view,
        hidesList: true,
        listView: tableView,
        animatesPresentation: configuration.empty.animatesPresentation,
        retry: { [weak self] in self?.reloadInitialContent() }
      )
    } else {
      transitionPresentationState(to: .content)
      presentationCoordinator.hideEmptyState(
        on: tableView,
        hostView: view,
        policy: configuration.layout.emptyPresentationPolicy,
        animatesPresentation: configuration.empty.animatesPresentation
      )
    }
  }

  private func transitionPresentationState(to state: FKListPresentationState) {
    presentationState = state
    delegate?.list(self, presentationStateChanged: state)
  }

  private func handleLoadFailure(_ error: Error, operation: FKListLoadCoordinator.Operation) {
    needsInitialSkeletonPresentation = false
    presentationCoordinator.hideSkeleton(
      on: tableView,
      policy: configuration.loading.skeletonPolicy,
      overlayHost: view
    )
    let presentation = FKListErrorPresentation(
      title: configuration.error.overridesTitle ?? "Unable to load",
      message: configuration.error.overridesMessage ?? error.localizedDescription
    )
    transitionPresentationState(to: .error(presentation))
    let errorConfig = makeEmptyStateConfiguration(for: .error(presentation))
      ?? presentationCoordinator.errorConfiguration(for: configuration, presentation: presentation)
    if !configuration.error.preservesContentOnError {
      replaceSnapshotWithoutPresentationUpdate(FKListSnapshot(), animatingDifferences: false)
    }
    presentationCoordinator.applyEmptyState(
      on: tableView,
      configuration: errorConfig,
      policy: configuration.layout.emptyPresentationPolicy,
      hostView: view,
      hidesList: !configuration.error.preservesContentOnError,
      listView: tableView,
      animatesPresentation: configuration.error.animatesPresentation,
      retry: { [weak self] in self?.reloadInitialContent() }
    )
    if operation == .refresh {
      tableView.fk_pullToRefresh?.endRefreshingWithError(error)
      delegate?.list(self, didRefresh: false)
    }
    if operation == .loadMore {
      tableView.fk_loadMore?.endRefreshingWithError(error)
    }
  }

  // MARK: - Refresh

  private func handlePullToRefresh(context: FKRefreshActionContext) async {
    delegate?.list(self, willRefresh: context)
    transitionPresentationState(to: .refreshing)
    presentationCoordinator.hideEmptyStateForRefreshIfNeeded(
      on: tableView,
      hostView: view,
      policy: configuration.layout.emptyPresentationPolicy
    )
    if configuration.refresh.resetsPaginationOnRefresh {
      pagination.resetForNewRequest()
      loadCoordinator.resetPaginationState()
    }
    if configuration.refresh.cancelsLoadMoreOnRefresh {
      loadCoordinator.cancelLoadMore()
    }
    if configuration.refresh.clearsSnapshotOnRefreshStart {
      // Avoid `updatePresentationAfterSnapshotApply` while `.refreshing` — empty overlay
      // must stay hidden until the refresh request finishes.
      replaceSnapshotWithoutPresentationUpdate(FKListSnapshot(), animatingDifferences: false)
    }
    let token = loadCoordinator.begin(.refresh)
    do {
      let result: FKListFetchResult
      if let dataProvider {
        result = try await dataProvider.fetchRefresh(page: pagination.page)
      } else {
        delegate?.list(self, didRefresh: false)
        tableView.fk_pullToRefresh?.endRefreshing(token: context.token)
        return
      }
      guard loadCoordinator.isCurrent(token: token, for: .refresh) else { return }
      loadCoordinator.updateHasMorePages(result.hasMorePages)
      applySnapshot(result.snapshot, animatingDifferences: true)
      tableView.fk_pullToRefresh?.endRefreshing(token: context.token)
      tableView.fk_loadMore?.resetToIdle()
      delegate?.list(self, didRefresh: true)
      presentationCoordinator.announceRefreshCompletionIfNeeded(configuration: configuration, succeeded: true)
    } catch {
      guard loadCoordinator.isCurrent(token: token, for: .refresh) else { return }
      if configuration.refresh.refreshFailureKeepsContent {
        transitionPresentationState(to: currentSnapshot.totalItemCount > 0 ? .content : .empty)
        if currentSnapshot.totalItemCount == 0 {
          updatePresentationAfterSnapshotApply()
        }
        tableView.fk_pullToRefresh?.endRefreshingWithError(error, token: context.token)
      } else {
        handleLoadFailure(error, operation: .refresh)
      }
      delegate?.list(self, didRefresh: false)
      presentationCoordinator.announceRefreshCompletionIfNeeded(configuration: configuration, succeeded: false)
    }
  }

  private func handleLoadMore(context: FKRefreshActionContext) async {
    guard loadCoordinator.hasMorePages else {
      tableView.fk_loadMore?.endRefreshingWithNoMoreData(token: context.token)
      delegate?.list(self, didReachEnd: ())
      return
    }
    guard case .content = presentationState else {
      tableView.fk_loadMore?.endRefreshing(token: context.token)
      return
    }
    transitionPresentationState(to: .loadingNextPage)
    let token = loadCoordinator.begin(.loadMore)
    let page = pagination.page
    delegate?.list(self, willLoadPage: page)
    do {
      guard let dataProvider else {
        tableView.fk_loadMore?.endRefreshing(token: context.token)
        transitionPresentationState(to: .content)
        return
      }
      let result = try await dataProvider.fetchNextPage(after: pagination)
      guard loadCoordinator.isCurrent(token: token, for: .loadMore) else { return }
      appendLoadMoreItems(from: result.snapshot)
      if result.hasMorePages {
        pagination.advance()
        tableView.fk_loadMore?.endRefreshing(token: context.token)
      } else {
        loadCoordinator.updateHasMorePages(false)
        tableView.fk_loadMore?.endRefreshingWithNoMoreData(token: context.token)
        delegate?.list(self, didReachEnd: ())
      }
      transitionPresentationState(to: .content)
      delegate?.list(self, didLoadPage: page, result: result)
    } catch {
      guard loadCoordinator.isCurrent(token: token, for: .loadMore) else { return }
      transitionPresentationState(to: .content)
      tableView.fk_loadMore?.endRefreshingWithError(error, token: context.token)
    }
  }

  private func appendLoadMoreItems(from snapshot: FKListSnapshot) {
    var working = currentSnapshot
    var changed = false
    for section in snapshot.sections where !section.items.isEmpty {
      if let index = working.sections.firstIndex(where: { $0.id == section.id }) {
        working.sections[index].items.append(contentsOf: section.items)
        changed = true
      } else {
        working.sections.append(section)
        changed = true
      }
    }
    guard changed else { return }
    applySnapshot(working, animatingDifferences: true)
  }

  private func assertDuplicateItemIDsIfNeeded(_ snapshot: FKListSnapshot) {
    #if DEBUG
    let duplicates = FKListSnapshotApplier.duplicateItemIDs(in: snapshot)
    if !duplicates.isEmpty {
      assertionFailure("FKListKit duplicate item IDs: \(duplicates)")
    }
    #endif
  }
}

// MARK: - UITableViewDelegate

extension FKDiffableTableViewController: UITableViewDelegate {
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let itemID = dataSource.itemIdentifier(for: indexPath) else { return }
    guard let item = currentSnapshot.item(withID: itemID) else { return }
    if case .preset(.checkbox(let row)) = item.kind {
      checkboxHandlerRegistry.handler(for: row.handlerID)?(itemID, !row.isChecked)
      tableView.deselectRow(at: indexPath, animated: true)
      return
    }
    if case .preset(.switch) = item.kind {
      tableView.deselectRow(at: indexPath, animated: true)
      return
    }
    guard item.resolvedIsSelectable else {
      tableView.deselectRow(at: indexPath, animated: true)
      return
    }
    if configuration.selection.playsHapticOnSelect {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    didSelectItem?(itemID)
    delegate?.list(self, didSelect: itemID)
    if case .single(let deselectOnSecondTap) = configuration.selection.mode, deselectOnSecondTap {
      tableView.deselectRow(at: indexPath, animated: true)
    }
  }

  public func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
    guard let itemID = dataSource.itemIdentifier(for: indexPath) else { return }
    didDeselectItem?(itemID)
    delegate?.list(self, didDeselect: itemID)
  }

  public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if let rowHeightProvider,
       let itemID = dataSource.itemIdentifier(for: indexPath),
       let item = currentSnapshot.item(withID: itemID) {
      return rowHeightProvider(item)
    }
    switch configuration.layout.rowHeightPolicy {
    case .automatic:
      return UITableView.automaticDimension
    case .fixed(let height):
      return height
    }
  }

  public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    guard currentSnapshot.sections.indices.contains(section) else { return nil }
    switch currentSnapshot.sections[section].header {
    case .title(let title):
      return title
    default:
      return nil
    }
  }

  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard currentSnapshot.sections.indices.contains(section) else { return nil }
    switch currentSnapshot.sections[section].header {
    case .subtitle(let title, let subtitle):
      let view = tableView.dequeueReusableHeaderFooterView(
        withIdentifier: FKListSectionHeaderView.reuseIdentifier
      ) as! FKListSectionHeaderView
      view.apply(title: title, subtitle: subtitle, appearance: configuration.appearance)
      return view
    case .custom(let providerID):
      return sectionViewProviders[providerID]?()
    default:
      return nil
    }
  }

  public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    guard currentSnapshot.sections.indices.contains(section) else { return nil }
    switch currentSnapshot.sections[section].footer {
    case .title(let title):
      let view = tableView.dequeueReusableHeaderFooterView(
        withIdentifier: FKListSectionFooterView.reuseIdentifier
      ) as! FKListSectionFooterView
      view.apply(text: title, appearance: configuration.appearance)
      return view
    case .subtitle(let title, let subtitle):
      let view = tableView.dequeueReusableHeaderFooterView(
        withIdentifier: FKListSectionHeaderView.reuseIdentifier
      ) as! FKListSectionHeaderView
      view.apply(title: title, subtitle: subtitle, appearance: configuration.appearance)
      return view
    case .custom(let providerID):
      return sectionViewProviders[providerID]?()
    case .none:
      return nil
    }
  }

  public func tableView(
    _ tableView: UITableView,
    trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration? {
    swipeActionsConfiguration(at: indexPath, edge: .trailing)
  }

  public func tableView(
    _ tableView: UITableView,
    leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
  ) -> UISwipeActionsConfiguration? {
    swipeActionsConfiguration(at: indexPath, edge: .leading)
  }

  private enum SwipeEdge {
    case leading
    case trailing
  }

  private func swipeActionsConfiguration(
    at indexPath: IndexPath,
    edge: SwipeEdge
  ) -> UISwipeActionsConfiguration? {
    guard let itemID = dataSource.itemIdentifier(for: indexPath),
          let item = currentSnapshot.item(withID: itemID),
          let swipeActions = item.swipeActions else { return nil }
    let actions = edge == .trailing ? swipeActions.trailing : swipeActions.leading
    guard !actions.isEmpty else { return nil }
    let contextual = actions.map { action -> UIContextualAction in
      let uiAction = UIContextualAction(style: mapSwipeStyle(action.style), title: action.title) { [weak self] _, _, completion in
        self?.swipeActionHandlerRegistry.handler(for: action.id)?(itemID)
        completion(true)
      }
      uiAction.accessibilityLabel = action.title
      if let icon = action.icon {
        uiAction.image = UIImage(systemName: icon.symbolName)
      }
      return uiAction
    }
    let config = UISwipeActionsConfiguration(actions: contextual)
    config.performsFirstActionWithFullSwipe = swipeActions.permitsFullSwipe
    return config
  }

  private func mapSwipeStyle(_ style: FKListSwipeActionStyle) -> UIContextualAction.Style {
    switch style {
    case .normal: return .normal
    case .destructive: return .destructive
    case .cancel: return .normal
    }
  }
}

// MARK: - Prefetching

extension FKDiffableTableViewController: UITableViewDataSourcePrefetching {
  public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    guard configuration.prefetch.isEnabled else { return }
    let ids = indexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
    delegate?.list(self, prefetchItems: ids)
  }

  public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
    guard configuration.prefetch.isEnabled else { return }
    let ids = indexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
    delegate?.list(self, cancelPrefetching: ids)
  }
}
