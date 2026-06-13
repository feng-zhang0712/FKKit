import FKCoreKit
import UIKit

/// Diffable collection list base controller with layout presets and refresh integration.
@MainActor
open class FKDiffableCollectionViewController: UIViewController {
  public let collectionView: UICollectionView
  public var configuration: FKListConfiguration {
    didSet { applyConfiguration() }
  }
  public var layoutPreset: FKListCollectionLayoutPreset {
    didSet {
      lastLayoutStructureSignature = nil
      rebuildLayout(snapshot: currentSnapshot)
    }
  }
  public var pagination = FKRefreshPagination()
  public private(set) var presentationState: FKListPresentationState = .initialLoading
  public private(set) var currentSnapshot = FKListSnapshot()

  public weak var delegate: FKListCollectionDelegate?
  public weak var dataProvider: FKListDataProviding?

  /// Swipe action handler registry; **table lists only** — collection lists do not wire swipe actions yet.
  public let swipeActionHandlerRegistry = FKListSwipeActionHandlerRegistry()
  public let switchHandlerRegistry = FKListSwitchHandlerRegistry()
  public let checkboxHandlerRegistry = FKListCheckboxHandlerRegistry()

  public var didSelectItem: ((FKListItemID) -> Void)?
  public var didDeselectItem: ((FKListItemID) -> Void)?

  /// Overrides ``FKListEmptyConfiguration/scenario`` when the next snapshot apply yields zero items.
  public var activeEmptyScenarioOverride: FKEmptyStateScenario?

  /// Invoked by ``reloadInitialContent()`` when ``dataProvider`` is nil.
  public var hostReloadHandler: (@MainActor (FKDiffableCollectionViewController) async throws -> Void)?

  /// Optional custom compositional layout builder when preset is insufficient.
  public var compositionalLayoutProvider: ((FKListSnapshot) -> UICollectionViewLayout)?

  private var dataSource: UICollectionViewDiffableDataSource<FKListSectionID, FKListItemID>!
  private let loadCoordinator = FKListLoadCoordinator()
  private let presentationCoordinator = FKListPresentationCoordinator()
  private let itemStore = FKListItemStore()
  private let cellRegistry = FKListCollectionCellRegistry()
  private var sectionViewProviders: [String: @MainActor (UICollectionView, IndexPath) -> UICollectionReusableView] = [:]
  private var needsInitialSkeletonPresentation = false
  private var lastLayoutStructureSignature: FKListCollectionLayoutStructureSignature?

  public init(
    configuration: FKListConfiguration = FKListDefaults.defaultConfiguration,
    layoutPreset: FKListCollectionLayoutPreset = .list
  ) {
    self.configuration = configuration
    self.layoutPreset = layoutPreset
    let layout = FKListCollectionLayoutFactory.makeLayout(preset: layoutPreset, snapshot: FKListSnapshot())
    self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func viewDidLoad() {
    super.viewDidLoad()
    setupCollectionView()
    setupDataSource()
    registerPresetCells()
    registerAdditionalCells(in: collectionView)
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

  open func applySnapshot(
    _ snapshot: FKListSnapshot,
    animatingDifferences: Bool = true,
    completion: (() -> Void)? = nil
  ) {
    assertDuplicateItemIDsIfNeeded(snapshot)
    rebuildLayoutIfNeeded(for: snapshot)
    commitSnapshot(
      snapshot,
      animatingDifferences: animatingDifferences,
      reloadIDs: snapshot.itemIDsWithChangedContent(comparedTo: currentSnapshot),
      reloadSectionIDs: [],
      completion: completion
    )
    updatePresentationAfterSnapshotApply()
  }

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
    rebuildLayoutIfNeeded(for: working)
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

  public func setPayload(_ payload: FKListItemPayload, for id: FKListItemID) {
    itemStore.setPayload(payload, for: id)
  }

  open func register<Cell: FKListCollectionCellConfigurable>(
    _ cellType: Cell.Type,
    forPayloadType payloadType: Cell.Item.Type
  ) {
    cellRegistry.register(cellType, forPayloadType: payloadType, in: collectionView)
  }

  open func registerAdditionalCells(in collectionView: UICollectionView) {}

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

  /// Host-driven initial load entry point.
  open func loadInitialContent(
    handler: @escaping @MainActor (FKDiffableCollectionViewController) async throws -> Void
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

  /// Applies ``FKListSelectionConfiguration`` to the collection view after nested config mutation.
  public func applySelectionConfiguration() {
    switch configuration.selection.mode {
    case .none:
      collectionView.allowsSelection = false
      collectionView.allowsMultipleSelection = false
    case .single:
      collectionView.allowsSelection = true
      collectionView.allowsMultipleSelection = false
    case .multiple:
      collectionView.allowsSelection = true
      collectionView.allowsMultipleSelection = true
    }
  }

  // MARK: - Private

  private func setupCollectionView() {
    view.backgroundColor = .systemBackground
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.backgroundColor = .systemBackground
    collectionView.delegate = self
    view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    registerLayoutSupplementaryAssets(on: collectionView.collectionViewLayout)
  }

  private func registerLayoutSupplementaryAssets(on layout: UICollectionViewLayout) {
    guard layoutPreset == .insetGroupedList else { return }
    layout.register(
      FKListCollectionBackgroundView.self,
      forDecorationViewOfKind: FKListCollectionBackgroundDecoration.kind
    )
  }

  private func setupDataSource() {
    let presetRegistration = UICollectionView.CellRegistration<FKListPresetCollectionCell, FKListItemID> {
      [weak self] cell, indexPath, itemID in
      guard let self, let item = self.currentSnapshot.item(withID: itemID),
            case .preset(let preset) = item.kind else { return }
      let context = FKListPresetCellContext(
        itemID: item.id,
        preset: preset,
        metadata: item.metadata,
        appearance: self.configuration.appearance,
        separatorMode: self.configuration.layout.separatorMode,
        switchHandlerRegistry: self.switchHandlerRegistry,
        checkboxHandlerRegistry: self.checkboxHandlerRegistry,
        displaysCardChrome: self.layoutPreset.displaysCollectionCardChrome
      )
      cell.configure(with: context)
    }

    dataSource = UICollectionViewDiffableDataSource<FKListSectionID, FKListItemID>(collectionView: collectionView) {
      [weak self] collectionView, indexPath, itemID in
      guard let self, let item = self.currentSnapshot.item(withID: itemID) else {
        return UICollectionViewCell()
      }
      switch item.kind {
      case .preset:
        return collectionView.dequeueConfiguredReusableCell(using: presetRegistration, for: indexPath, item: itemID)
      case .custom(let custom):
        guard let entry = self.cellRegistry.entry(for: custom.cellTypeIdentifier),
              let payload = self.itemStore.payload(for: item.id) else {
          return UICollectionViewCell()
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: entry.reuseIdentifier, for: indexPath)
        entry.configure(cell, payload)
        return cell
      }
    }

    dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
      guard let self, kind == UICollectionView.elementKindSectionHeader else { return nil }
      guard self.currentSnapshot.sections.indices.contains(indexPath.section) else { return nil }
      let section = self.currentSnapshot.sections[indexPath.section]
      switch section.header {
      case .title, .subtitle:
        let view = collectionView.dequeueReusableSupplementaryView(
          ofKind: kind,
          withReuseIdentifier: FKListCollectionSectionHeaderView.reuseIdentifier,
          for: indexPath
        ) as! FKListCollectionSectionHeaderView
        if let header = section.header {
          view.apply(header: header, appearance: self.configuration.appearance)
        }
        return view
      case .custom(let providerID):
        if let provider = self.sectionViewProviders[providerID] {
          return provider(collectionView, indexPath)
        }
        return collectionView.dequeueReusableSupplementaryView(
          ofKind: kind,
          withReuseIdentifier: FKListCollectionSectionHeaderView.reuseIdentifier,
          for: indexPath
        )
      case .none:
        return collectionView.dequeueReusableSupplementaryView(
          ofKind: kind,
          withReuseIdentifier: FKListCollectionSectionHeaderView.reuseIdentifier,
          for: indexPath
        )
      }
    }
  }

  private func registerPresetCells() {
    collectionView.register(
      FKListCollectionSectionHeaderView.self,
      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
      withReuseIdentifier: FKListCollectionSectionHeaderView.reuseIdentifier
    )
  }

  /// Registers a custom collection section header provider.
  ///
  /// The provider must dequeue and return exactly one supplementary view for the requested `indexPath`.
  public func registerSectionHeaderProvider(
    id: String,
    provider: @escaping @MainActor (UICollectionView, IndexPath) -> UICollectionReusableView
  ) {
    sectionViewProviders[id] = provider
  }

  private func applyConfiguration() {
    collectionView.contentInset = configuration.layout.contentInsets
    collectionView.scrollIndicatorInsets = configuration.layout.contentInsets
    applySelectionConfiguration()
    collectionView.prefetchDataSource = configuration.prefetch.isEnabled ? self : nil
  }

  private func installRefreshControlsIfNeeded() {
    if configuration.refresh.isPullToRefreshEnabled {
      collectionView.fk_addPullToRefresh(contextAsyncAction: { [weak self] context in
        await self?.handlePullToRefresh(context: context)
      })
    }
    if configuration.refresh.isLoadMoreEnabled {
      collectionView.fk_addLoadMore(
        configuration: configuration.refresh.loadMoreRefreshConfiguration(),
        contextAsyncAction: { [weak self] context in
          await self?.handleLoadMore(context: context)
        }
      )
    }
  }

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
      ? collectionView.indexPathsForSelectedItems?.compactMap { dataSource.itemIdentifier(for: $0) } ?? []
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

  /// Programmatically selects an item by id.
  public func selectItem(withID id: FKListItemID, animated: Bool = true, scrollPosition: UICollectionView.ScrollPosition = []) {
    guard let indexPath = indexPath(for: id) else { return }
    collectionView.selectItem(at: indexPath, animated: animated, scrollPosition: scrollPosition)
  }

  /// Programmatically deselects an item by id.
  public func deselectItem(withID id: FKListItemID, animated: Bool = true) {
    guard let indexPath = indexPath(for: id) else { return }
    collectionView.deselectItem(at: indexPath, animated: animated)
  }

  private func indexPath(for itemID: FKListItemID) -> IndexPath? {
    for (sectionIndex, section) in currentSnapshot.sections.enumerated() {
      if let row = section.items.firstIndex(where: { $0.id == itemID }) {
        return IndexPath(item: row, section: sectionIndex)
      }
    }
    return nil
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

  private func rebuildLayoutIfNeeded(for snapshot: FKListSnapshot) {
    if compositionalLayoutProvider != nil {
      rebuildLayout(snapshot: snapshot)
      return
    }
    let signature = FKListCollectionLayoutStructureSignature(preset: layoutPreset, snapshot: snapshot)
    guard signature != lastLayoutStructureSignature else { return }
    lastLayoutStructureSignature = signature
    rebuildLayout(snapshot: snapshot)
  }

  private func rebuildLayout(snapshot: FKListSnapshot) {
    let layout: UICollectionViewLayout
    if let provider = compositionalLayoutProvider {
      layout = provider(snapshot)
    } else {
      layout = FKListCollectionLayoutFactory.makeLayout(preset: layoutPreset, snapshot: snapshot)
    }
    collectionView.setCollectionViewLayout(layout, animated: false)
    registerLayoutSupplementaryAssets(on: layout)
  }

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
      on: collectionView,
      policy: configuration.loading.skeletonPolicy,
      overlayHost: view
    )
    view.fk_bringSkeletonOverlayToFrontIfNeeded()
  }

  private func syncEmptyStateOverlayIfNeeded() {
    let policy = configuration.layout.emptyPresentationPolicy
    if currentSnapshot.totalItemCount > 0 {
      guard collectionView.fk_emptyStateView != nil else { return }
      presentationCoordinator.hideEmptyState(
        on: collectionView,
        hostView: view,
        policy: policy,
        animatesPresentation: false
      )
      return
    }
    guard case .empty = presentationState else { return }
    collectionView.fk_refreshEmptyStateAutomatically { [weak self] action in
      if action.kind == .primary { self?.reloadInitialContent() }
    }
  }

  private func updatePresentationAfterSnapshotApply() {
    needsInitialSkeletonPresentation = false
    presentationCoordinator.hideSkeleton(
      on: collectionView,
      policy: configuration.loading.skeletonPolicy,
      overlayHost: view
    )
    if currentSnapshot.totalItemCount == 0 {
      let scenario = activeEmptyScenarioOverride ?? configuration.empty.scenario
      let emptyConfig = makeEmptyStateConfiguration(for: .empty)
        ?? presentationCoordinator.emptyConfiguration(for: configuration, scenario: scenario)
      transitionPresentationState(to: .empty)
      presentationCoordinator.applyEmptyState(
        on: collectionView,
        configuration: emptyConfig,
        policy: configuration.layout.emptyPresentationPolicy,
        hostView: view,
        hidesList: true,
        listView: collectionView,
        animatesPresentation: configuration.empty.animatesPresentation,
        retry: { [weak self] in self?.reloadInitialContent() }
      )
    } else {
      transitionPresentationState(to: .content)
      presentationCoordinator.hideEmptyState(
        on: collectionView,
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
      on: collectionView,
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
      on: collectionView,
      configuration: errorConfig,
      policy: configuration.layout.emptyPresentationPolicy,
      hostView: view,
      hidesList: !configuration.error.preservesContentOnError,
      listView: collectionView,
      animatesPresentation: configuration.error.animatesPresentation,
      retry: { [weak self] in self?.reloadInitialContent() }
    )
    if operation == .refresh {
      collectionView.fk_pullToRefresh?.endRefreshingWithError(error)
      delegate?.list(self, didRefresh: false)
    }
    if operation == .loadMore {
      collectionView.fk_loadMore?.endRefreshingWithError(error)
    }
  }

  private func handlePullToRefresh(context: FKRefreshActionContext) async {
    delegate?.list(self, willRefresh: context)
    transitionPresentationState(to: .refreshing)
    presentationCoordinator.hideEmptyStateForRefreshIfNeeded(
      on: collectionView,
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
        collectionView.fk_pullToRefresh?.endRefreshing(token: context.token)
        return
      }
      guard loadCoordinator.isCurrent(token: token, for: .refresh) else { return }
      loadCoordinator.updateHasMorePages(result.hasMorePages)
      applySnapshot(result.snapshot, animatingDifferences: true)
      collectionView.fk_pullToRefresh?.endRefreshing(token: context.token)
      collectionView.fk_loadMore?.resetToIdle()
      delegate?.list(self, didRefresh: true)
      presentationCoordinator.announceRefreshCompletionIfNeeded(configuration: configuration, succeeded: true)
    } catch {
      guard loadCoordinator.isCurrent(token: token, for: .refresh) else { return }
      if configuration.refresh.refreshFailureKeepsContent {
        transitionPresentationState(to: currentSnapshot.totalItemCount > 0 ? .content : .empty)
        if currentSnapshot.totalItemCount == 0 {
          updatePresentationAfterSnapshotApply()
        }
        collectionView.fk_pullToRefresh?.endRefreshingWithError(error, token: context.token)
      } else {
        handleLoadFailure(error, operation: .refresh)
      }
      delegate?.list(self, didRefresh: false)
      presentationCoordinator.announceRefreshCompletionIfNeeded(configuration: configuration, succeeded: false)
    }
  }

  private func handleLoadMore(context: FKRefreshActionContext) async {
    guard loadCoordinator.hasMorePages else {
      collectionView.fk_loadMore?.endRefreshingWithNoMoreData(token: context.token)
      delegate?.list(self, didReachEnd: ())
      return
    }
    guard case .content = presentationState else {
      collectionView.fk_loadMore?.endRefreshing(token: context.token)
      return
    }
    transitionPresentationState(to: .loadingNextPage)
    let token = loadCoordinator.begin(.loadMore)
    let page = pagination.page
    delegate?.list(self, willLoadPage: page)
    do {
      guard let dataProvider else {
        collectionView.fk_loadMore?.endRefreshing(token: context.token)
        transitionPresentationState(to: .content)
        return
      }
      let result = try await dataProvider.fetchNextPage(after: pagination)
      guard loadCoordinator.isCurrent(token: token, for: .loadMore) else { return }
      appendLoadMoreItems(from: result.snapshot)
      if result.hasMorePages {
        pagination.advance()
        collectionView.fk_loadMore?.endRefreshing(token: context.token)
      } else {
        loadCoordinator.updateHasMorePages(false)
        collectionView.fk_loadMore?.endRefreshingWithNoMoreData(token: context.token)
        delegate?.list(self, didReachEnd: ())
      }
      transitionPresentationState(to: .content)
      delegate?.list(self, didLoadPage: page, result: result)
    } catch {
      guard loadCoordinator.isCurrent(token: token, for: .loadMore) else { return }
      transitionPresentationState(to: .content)
      collectionView.fk_loadMore?.endRefreshingWithError(error, token: context.token)
    }
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

extension FKDiffableCollectionViewController: UICollectionViewDelegate {
  public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    guard let itemID = dataSource.itemIdentifier(for: indexPath),
          let item = currentSnapshot.item(withID: itemID) else { return }
    if case .preset(.checkbox(let row)) = item.kind {
      checkboxHandlerRegistry.handler(for: row.handlerID)?(itemID, !row.isChecked)
      collectionView.deselectItem(at: indexPath, animated: true)
      return
    }
    if case .preset(.switch) = item.kind {
      collectionView.deselectItem(at: indexPath, animated: true)
      return
    }
    guard item.resolvedIsSelectable else {
      collectionView.deselectItem(at: indexPath, animated: true)
      return
    }
    if configuration.selection.playsHapticOnSelect {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    didSelectItem?(itemID)
    delegate?.list(self, didSelect: itemID)
    if case .single(let deselectOnSecondTap) = configuration.selection.mode, deselectOnSecondTap {
      collectionView.deselectItem(at: indexPath, animated: true)
    }
  }

  public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
    guard let itemID = dataSource.itemIdentifier(for: indexPath) else { return }
    didDeselectItem?(itemID)
    delegate?.list(self, didDeselect: itemID)
  }
}

extension FKDiffableCollectionViewController: UICollectionViewDataSourcePrefetching {
  public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    guard configuration.prefetch.isEnabled else { return }
    let ids = indexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
    delegate?.list(self, prefetchItems: ids)
  }

  public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
    guard configuration.prefetch.isEnabled else { return }
    let ids = indexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
    delegate?.list(self, cancelPrefetching: ids)
  }
}
