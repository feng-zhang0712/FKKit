import UIKit

/// Hosts a ``FKTabBar`` and a `UIPageViewController`-powered pager with bidirectional synchronization.
@MainActor
public final class FKPagingController: UIViewController {
  public weak var delegate: FKPagingControllerDelegate?

  /// Optional dynamic tab/page metadata source.
  public weak var dataSource: FKPagingDataSource?

  public weak var tabBarDelegate: FKTabBarDelegate? {
    didSet { tabCoordinator.bind(tabBar: tabBar, forwardedDelegate: tabBarDelegate) }
  }

  public let tabBar: FKTabBar

  public private(set) var selectedIndex: Int
  public var selectedItemID: String? { tabBar.selectedItemID }
  public private(set) var pendingPageIndex: Int?
  public var stateSnapshot: FKPagingStateSnapshot { stateMachine.snapshot }

  /// Read-only access to the internal paging scroll view for advanced gesture wiring.
  public var pagingScrollView: UIScrollView? { scrollView }

  /// Accessory expansion state forwarded to ``FKTabBar/expandedItemID``.
  public var expandedTabItemID: String? {
    get { tabBar.expandedItemID }
    set { tabBar.expandedItemID = newValue }
  }

  public var isTransitionActive: Bool {
    switch stateMachine.snapshot.phase {
    case .idle, .interrupted: return false
    case .dragging, .settling, .programmaticSwitch: return true
    }
  }

  public var pageCount: Int { pageStore.pageCount }

  public var configuration: FKPagingConfiguration {
    didSet { applyConfiguration() }
  }

  private var pageViewController: UIPageViewController
  private let stateMachine: FKPagingStateMachine
  private let pageStore: FKPagingPageStore
  private let tabCoordinator = FKPagingTabBarCoordinator()

  private var pendingProgrammaticIndex: Int?
  private var queuedProgrammaticTarget: Int?
  private var queuedProgrammaticAnimated: Bool = true
  private var scrollView: UIScrollView?
  private var tabHeightConstraint: NSLayoutConstraint?
  private var layoutConstraints = LayoutConstraints()
  private var didInstallPagingPanRequiresNavigationPopFailure = false
  private var installedNestedScrollPanRecognizers = Set<ObjectIdentifier>()
  private var lastNestedScrollInstallIndex: Int?
  private var appliedInterPageSpacing: CGFloat
  private var lastDisplayedIndex: Int?
  private var displayedPageIndices = Set<Int>()
  private var pendingDisplayIndices = Set<Int>()
  private let emptyStateLabel = UILabel()

  public init(
    tabs: [FKTabBarItem],
    viewControllers: [UIViewController],
    selectedIndex: Int = 0,
    tabConfiguration: FKTabBarConfiguration = FKTabBarPresets.pagerHeader(),
    configuration: FKPagingConfiguration = FKPagingConfiguration()
  ) {
    let visibleCount = Self.visibleTabCount(from: tabs)
    let safeCount = min(visibleCount, viewControllers.count)
    self.pageStore = FKPagingPageStore(viewControllers: Array(viewControllers.prefix(safeCount)))
    self.selectedIndex = safeCount > 0 ? max(0, min(selectedIndex, safeCount - 1)) : 0
    self.stateMachine = FKPagingStateMachine(initialIndex: self.selectedIndex)
    self.configuration = configuration
    self.appliedInterPageSpacing = configuration.interPageSpacing
    self.tabBar = FKTabBar(items: tabs, selectedIndex: self.selectedIndex, configuration: tabConfiguration)
    self.pageViewController = Self.makePageViewController(interPageSpacing: configuration.interPageSpacing)
    super.init(nibName: nil, bundle: nil)
    commonInit()
  }

  public init(
    tabs: [FKTabBarItem],
    pageCount: Int,
    pageProvider: @escaping (Int) -> UIViewController,
    selectedIndex: Int = 0,
    tabConfiguration: FKTabBarConfiguration = FKTabBarPresets.pagerHeader(),
    configuration: FKPagingConfiguration = FKPagingConfiguration()
  ) {
    let visibleCount = Self.visibleTabCount(from: tabs)
    let safeCount = min(visibleCount, max(0, pageCount))
    self.pageStore = FKPagingPageStore(pageCount: safeCount, provider: pageProvider)
    self.selectedIndex = safeCount > 0 ? max(0, min(selectedIndex, safeCount - 1)) : 0
    self.stateMachine = FKPagingStateMachine(initialIndex: self.selectedIndex)
    self.configuration = configuration
    self.appliedInterPageSpacing = configuration.interPageSpacing
    self.tabBar = FKTabBar(items: tabs, selectedIndex: self.selectedIndex, configuration: tabConfiguration)
    self.pageViewController = Self.makePageViewController(interPageSpacing: configuration.interPageSpacing)
    super.init(nibName: nil, bundle: nil)
    commonInit()
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    setupEmptyStateLabel()
    setupHierarchy()
    installInitialPage()
    preloadAndCompact(at: selectedIndex)
    updateEmptyStateVisibility()
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    attachScrollViewIfNeeded()
    updateTabBarHeightIfNeeded()
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.tabBar.realignSelection(animated: false)
    })
  }

  public override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    guard configuration.evictPagesOnMemoryWarning else { return }
    pageStore.compactCache(selectedIndex: selectedIndex, retention: .keepNear(distance: 0)) { [weak self] index, controller in
      self?.notifyEndDisplaying(controller, at: index)
    }
  }

  /// Returns the internal ``FKButton`` for a visible tab (popover/menu anchoring).
  public func visibleTabButton(at index: Int) -> FKButton? {
    tabBar.visibleItemButton(at: index)
  }

  /// Commits a pending controlled switch or navigates directly to `index`.
  ///
  /// Does not consult ``FKPagingControllerDelegate/pagingController(_:shouldSwitchTo:reason:)`` — call after host-side validation.
  public func commitPageSwitch(to index: Int, animated: Bool = true) {
    guard pageCount > 0 else { return }
    let target = min(max(0, index), pageCount - 1)
    clearPendingPageIndex(notifyCancel: false)
    tabBar.setSelectedIndex(target, animated: animated, notify: false, reason: .programmatic)
    performProgrammaticSwitch(to: target, animated: animated)
  }

  public func cancelPendingPageSwitch() {
    guard pendingPageIndex != nil else { return }
    clearPendingPageIndex(notifyCancel: true)
    tabCoordinator.syncSettled(index: selectedIndex, animated: true)
    applyPageHostContent(animated: true)
  }

  @discardableResult
  public func setSelectedIndex(_ index: Int, animated: Bool = true) -> Bool {
    requestSwitch(to: index, animated: animated, reason: .programmatic)
  }

  @discardableResult
  public func setSelectedIndex(forItemID id: String, animated: Bool = true) -> Bool {
    guard let index = tabBar.visibleItems.firstIndex(where: { $0.id == id }) else { return false }
    return requestSwitch(to: index, animated: animated, reason: .programmatic)
  }

  /// Drops or replaces the page at `index`. Lazy mode evicts cache; eager mode replaces when `replacingWith` is provided.
  public func invalidatePage(at index: Int, replacingWith replacement: UIViewController? = nil) {
    guard index >= 0, index < pageCount else { return }
    if pageStore.isEagerMode {
      guard let replacement else { return }
      guard let removed = pageStore.replaceEagerController(at: index, with: replacement) else { return }
      notifyEndDisplaying(removed, at: index)
      FKPagingScrollUtilities.detachFromParentIfNeeded(removed)
      if index == selectedIndex {
        displayedPageIndices.remove(index)
        lastDisplayedIndex = nil
        applyPageHostContent(animated: false)
        notifyWillDisplay(at: index)
        publishDisplayedPage(at: index, force: true)
      }
      return
    }
    guard let removed = pageStore.invalidatePage(at: index) else { return }
    notifyEndDisplaying(removed, at: index)
    FKPagingScrollUtilities.detachFromParentIfNeeded(removed)
    if index == selectedIndex {
      applyPageHostContent(animated: false)
      notifyWillDisplay(at: index)
      publishDisplayedPage(at: index, force: true)
    }
  }

  /// Applies tab and page mutations incrementally without a full ``setContent`` reset.
  public func applyContentChanges(
    _ changes: [FKPagingContentChange],
    updatePolicy: FKTabBar.ItemsUpdatePolicy = .preserveSelection,
    animated: Bool = false,
    completion: (() -> Void)? = nil
  ) {
    let tabChanges = changes.compactMap { change -> FKTabBarItemChange? in
      if case .tab(let tabChange) = change { return tabChange }
      return nil
    }
    let invalidations = changes.compactMap { change -> Int? in
      if case .invalidatePage(let index) = change { return index }
      return nil
    }

    let applyInvalidations = { [weak self] in
      guard let self else { return }
      for index in invalidations {
        self.invalidatePage(at: index)
      }
      let visibleCount = self.tabBar.visibleItems.count
      self.pageStore.syncPageCount(visibleCount) { evictedIndex, controller in
        self.notifyEndDisplaying(controller, at: evictedIndex)
      }
      self.selectedIndex = min(self.selectedIndex, max(0, visibleCount - 1))
      self.stateMachine.settle(at: self.selectedIndex)
      self.applyPageHostContent(animated: false)
      self.tabCoordinator.syncSettled(index: self.selectedIndex, animated: false)
      self.updateEmptyStateVisibility()
      self.updateSwipeEnabledForCurrentPage()
      completion?()
    }

    guard !tabChanges.isEmpty else {
      applyInvalidations()
      return
    }

    tabBar.applyChanges(tabChanges, updatePolicy: updatePolicy, animated: animated) { [weak self] in
      applyInvalidations()
    }
  }

  /// Reloads tabs from ``dataSource`` and synchronizes page count. Eager hosts require ``FKPagingEagerDataSource``.
  public func reloadFromDataSource(selectedIndex: Int? = nil) {
    guard let dataSource else { return }
    let count = max(0, dataSource.numberOfPages(in: self))
    let tabs = (0..<count).map { dataSource.pagingController(self, tabItemAt: $0) }
    if let eagerSource = dataSource as? FKPagingEagerDataSource {
      let pages = (0..<count).map { eagerSource.pagingController(self, viewControllerAt: $0) }
      setContent(tabs: tabs, viewControllers: pages, selectedIndex: selectedIndex)
      return
    }
    tabBar.reload(items: tabs, updatePolicy: .preserveSelection)
    pageStore.syncPageCount(Self.visibleTabCount(from: tabs)) { [weak self] index, controller in
      self?.notifyEndDisplaying(controller, at: index)
    }
    let target = selectedIndex ?? min(self.selectedIndex, max(0, pageCount - 1))
    self.selectedIndex = pageCount > 0 ? min(max(0, target), pageCount - 1) : 0
    stateMachine.settle(at: self.selectedIndex)
    applyPageHostContent(animated: false)
    tabCoordinator.syncSettled(index: self.selectedIndex, animated: false)
    updateEmptyStateVisibility()
  }

  public func setContent(tabs: [FKTabBarItem], viewControllers: [UIViewController], selectedIndex: Int? = nil) {
    applyContentUpdate(
      tabs: tabs,
      pageCount: min(Self.visibleTabCount(from: tabs), viewControllers.count),
      viewControllers: viewControllers,
      pageProvider: nil,
      selectedIndex: selectedIndex
    )
  }

  public func setContent(
    tabs: [FKTabBarItem],
    pageCount: Int,
    pageProvider: @escaping (Int) -> UIViewController,
    selectedIndex: Int? = nil
  ) {
    applyContentUpdate(
      tabs: tabs,
      pageCount: min(Self.visibleTabCount(from: tabs), max(0, pageCount)),
      viewControllers: [],
      pageProvider: pageProvider,
      selectedIndex: selectedIndex
    )
  }

}

// MARK: - Tab coordinator

extension FKPagingController: FKPagingTabBarCoordinatorDelegate {
  func pagingCoordinatorDidRequestSwitch(to index: Int, animated: Bool) {
    _ = requestSwitch(to: index, animated: animated, reason: .userTabTap)
  }

  func pagingCoordinatorDidRequestSelection(at index: Int) {
    guard shouldAllowSwitch(to: index, reason: .userTabTap) else { return }
    assignPendingPageIndex(index, reason: .userTabTap)
  }

  func pagingCoordinatorDidReselect(at index: Int) {
    guard index == selectedIndex, configuration.reselectBehavior == .scrollPageToTop else { return }
    scrollCurrentPageToTop()
  }
}

// MARK: - UIPageViewController

extension FKPagingController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard allowsSwipeFromCurrentPage(in: .reverse) else { return nil }
    guard let index = pageStore.index(of: viewController), index > 0 else { return nil }
    return pageStore.controller(at: index - 1)
  }

  public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
    guard allowsSwipeFromCurrentPage(in: .forward) else { return nil }
    guard let index = pageStore.index(of: viewController), index < pageCount - 1 else { return nil }
    return pageStore.controller(at: index + 1)
  }

  public func pageViewController(
    _ pageViewController: UIPageViewController,
    didFinishAnimating finished: Bool,
    previousViewControllers: [UIViewController],
    transitionCompleted completed: Bool
  ) {
    if !finished {
      revertInteractiveSwitch(animated: false)
      return
    }
    guard completed,
          let current = pageViewController.viewControllers?.first,
          let index = pageStore.index(of: current) else {
      revertInteractiveSwitch(animated: false)
      return
    }
    handleInteractiveSettle(to: index)
  }
}

// MARK: - Interactive scrolling

extension FKPagingController: UIScrollViewDelegate {
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    guard isSwipePagingEnabled else { return }
    stateMachine.beginDragging(from: selectedIndex, to: selectedIndex)
    notifyPhase()
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard isSwipePagingEnabled else { return }
    guard pendingProgrammaticIndex == nil else { return }
    guard pageCount > 1 else { return }
    let width = max(1, scrollView.bounds.width)
    var delta = scrollView.contentOffset.x - width
    if view.effectiveUserInterfaceLayoutDirection == .rightToLeft { delta = -delta }
    guard abs(delta) > 0.0001 else { return }
    let direction = delta > 0 ? 1 : -1
    let from = selectedIndex
    let to = from + direction
    guard to >= 0, to < pageCount else { return }
    guard allowsSwipeFromCurrentPage(in: direction > 0 ? .forward : .reverse) else { return }
    let progress = min(1, abs(delta) / width)
    stateMachine.updateDraggingProgress(progress, from: from, to: to)
    tabCoordinator.syncProgress(from: from, to: to, progress: progress)
    notifyPhase()
  }

  public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if decelerate {
      stateMachine.beginSettling()
      notifyPhase()
    }
  }
}

// MARK: - Private

private extension FKPagingController {
  struct LayoutConstraints {
    var tabTop: NSLayoutConstraint?
    var tabBottom: NSLayoutConstraint?
    var pageTop: NSLayoutConstraint?
    var pageBottom: NSLayoutConstraint?
    var pageLeading: NSLayoutConstraint?
    var pageTrailing: NSLayoutConstraint?
  }

  static func makePageViewController(interPageSpacing: CGFloat) -> UIPageViewController {
    UIPageViewController(
      transitionStyle: .scroll,
      navigationOrientation: .horizontal,
      options: [.interPageSpacing: NSNumber(value: Double(max(0, interPageSpacing)))]
    )
  }

  static func visibleTabCount(from tabs: [FKTabBarItem]) -> Int {
    tabs.filter { !$0.isHidden }.count
  }

  var isSwipePagingEnabled: Bool {
    configuration.allowsSwipePaging
      && (configuration.allowsSwipePagingFrom?(selectedIndex) ?? true)
  }

  func allowsSwipeFromCurrentPage(in direction: FKPagingNavigationDirection) -> Bool {
    guard configuration.allowsSwipePaging else { return false }
    guard configuration.allowsSwipePagingFrom?(selectedIndex) ?? true else { return false }
    return configuration.allowsSwipePagingTo?(selectedIndex, direction) ?? true
  }

  func commonInit() {
    tabCoordinator.delegate = self
    tabCoordinator.bind(tabBar: tabBar, forwardedDelegate: tabBarDelegate)
    tabCoordinator.applyPageSwitchGate(configuration.pageSwitchGate, scope: configuration.pageSwitchGateScope)
    pageViewController.dataSource = self
    pageViewController.delegate = self
  }

  @discardableResult
  func requestSwitch(to index: Int, animated: Bool, reason: FKPagingSwitchReason) -> Bool {
    guard pageCount > 0 else { return false }
    let target = min(max(0, index), pageCount - 1)
    guard target != selectedIndex else {
      tabCoordinator.syncSettled(index: target, animated: false)
      return true
    }
    guard shouldAllowSwitch(to: target, reason: reason) else {
      tabCoordinator.syncSettled(index: selectedIndex, animated: animated)
      return false
    }
    if usesControlledGate(for: reason) {
      assignPendingPageIndex(target, reason: reason)
      tabCoordinator.syncSettled(index: selectedIndex, animated: animated)
      return true
    }
    if reason != .userSwipe {
      performProgrammaticSwitch(to: target, animated: animated)
    }
    return true
  }

  func performProgrammaticSwitch(to target: Int, animated: Bool) {
    clearPendingPageIndex(notifyCancel: false)
    beginProgrammaticTransition(to: target, animated: animated)
  }

  func assignPendingPageIndex(_ index: Int, reason: FKPagingSwitchReason) {
    pendingPageIndex = index
    delegate?.pagingController(self, didRequestPageSwitchTo: index, reason: reason)
  }

  func clearPendingPageIndex(notifyCancel: Bool) {
    guard pendingPageIndex != nil else { return }
    pendingPageIndex = nil
    if notifyCancel {
      delegate?.pagingControllerDidCancelPendingPageSwitch(self)
    }
  }

  func shouldAllowSwitch(to index: Int, reason: FKPagingSwitchReason) -> Bool {
    delegate?.pagingController(self, shouldSwitchTo: index, reason: reason) ?? true
  }

  func usesControlledGate(for reason: FKPagingSwitchReason) -> Bool {
    guard configuration.pageSwitchGate == .controlled else { return false }
    switch (configuration.pageSwitchGateScope, reason) {
    case (.tabSelectionOnly, .userTabTap): return true
    case (.swipePagingOnly, .userSwipe): return true
    case (.all, .userTabTap), (.all, .userSwipe): return true
    default: return false
    }
  }

  func handleInteractiveSettle(to index: Int) {
    if usesControlledGate(for: .userSwipe) {
      assignPendingPageIndex(index, reason: .userSwipe)
      revertInteractiveSwitch(animated: true, preservePending: true)
      return
    }
    guard shouldAllowSwitch(to: index, reason: .userSwipe) else {
      revertInteractiveSwitch(animated: true)
      return
    }
    settle(at: index, animatedTab: true)
  }

  func revertInteractiveSwitch(animated: Bool, preservePending: Bool = false) {
    stateMachine.interrupt()
    if !preservePending { clearPendingPageIndex(notifyCancel: true) }
    tabCoordinator.syncSettled(index: selectedIndex, animated: animated)
    applyPageHostContent(animated: animated)
    notifyPhase()
  }

  func applyContentUpdate(
    tabs: [FKTabBarItem],
    pageCount: Int,
    viewControllers: [UIViewController],
    pageProvider: ((Int) -> UIViewController)?,
    selectedIndex: Int?
  ) {
    let safeCount = max(0, pageCount)
    cancelProgrammaticTransitionPipeline()
    clearPendingPageIndex(notifyCancel: false)
    pageStore.reset(
      pageCount: safeCount,
      provider: pageProvider,
      controllers: Array(viewControllers.prefix(safeCount)),
      onEvict: { [weak self] index, controller in self?.notifyEndDisplaying(controller, at: index) }
    )
    lastDisplayedIndex = nil
    displayedPageIndices.removeAll()
    pendingDisplayIndices.removeAll()
    tabBar.reload(items: tabs, updatePolicy: .preserveSelection)
    let target = selectedIndex ?? min(self.selectedIndex, max(0, safeCount - 1))
    self.selectedIndex = safeCount > 0 ? min(max(0, target), safeCount - 1) : 0
    stateMachine.settle(at: self.selectedIndex)
    applyConfiguration()
    applyPageHostContent(animated: false)
    tabCoordinator.syncSettled(index: self.selectedIndex, animated: false)
    preloadAndCompact(at: self.selectedIndex)
    updateEmptyStateVisibility()
    notifyPhase()
    notifyWillDisplay(at: self.selectedIndex)
    publishDisplayedPage(at: self.selectedIndex, force: true)
  }

  func setupEmptyStateLabel() {
    emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
    emptyStateLabel.font = .preferredFont(forTextStyle: .body)
    emptyStateLabel.textColor = .secondaryLabel
    emptyStateLabel.textAlignment = .center
    emptyStateLabel.numberOfLines = 0
    emptyStateLabel.isHidden = true
    view.addSubview(emptyStateLabel)
    NSLayoutConstraint.activate([
      emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
      emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
    ])
  }

  func updateEmptyStateVisibility() {
    let showEmpty = pageCount == 0 && configuration.emptyStateConfiguration.isEnabled
    emptyStateLabel.isHidden = !showEmpty
    emptyStateLabel.text = configuration.emptyStateConfiguration.message
    pageViewController.view.isHidden = showEmpty
    tabBar.isHidden = showEmpty
  }

  func setupHierarchy() {
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    installPageViewControllerInHierarchy(pageViewController)
    view.addSubview(tabBar)
    tabHeightConstraint = tabBar.heightAnchor.constraint(equalToConstant: resolvedTabBarHeight())
    tabHeightConstraint?.isActive = true
    NSLayoutConstraint.activate([
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    rebindPageViewHorizontalConstraints()
    applyTabBarLayout()
    attachScrollViewIfNeeded()
  }

  func rebindPageViewHorizontalConstraints() {
    layoutConstraints.pageLeading?.isActive = false
    layoutConstraints.pageTrailing?.isActive = false
    layoutConstraints.pageLeading = pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor)
    layoutConstraints.pageTrailing = pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
    layoutConstraints.pageLeading?.isActive = true
    layoutConstraints.pageTrailing?.isActive = true
  }

  func applyTabBarLayout() {
    layoutConstraints.tabTop?.isActive = false
    layoutConstraints.tabBottom?.isActive = false
    layoutConstraints.pageTop?.isActive = false
    layoutConstraints.pageBottom?.isActive = false

    switch configuration.tabBarPosition {
    case .top:
      layoutConstraints.tabTop = tabBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
      layoutConstraints.pageTop = pageViewController.view.topAnchor.constraint(equalTo: tabBar.bottomAnchor)
      layoutConstraints.pageBottom = pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
    case .bottom:
      layoutConstraints.pageTop = pageViewController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
      layoutConstraints.pageBottom = pageViewController.view.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
      layoutConstraints.tabBottom = tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    }

    layoutConstraints.tabTop?.isActive = configuration.tabBarPosition == .top
    layoutConstraints.tabBottom?.isActive = configuration.tabBarPosition == .bottom
    layoutConstraints.pageTop?.isActive = true
    layoutConstraints.pageBottom?.isActive = true
  }

  func installPageViewControllerInHierarchy(_ controller: UIPageViewController) {
    addChild(controller)
    controller.view.translatesAutoresizingMaskIntoConstraints = false
    view.insertSubview(controller.view, belowSubview: emptyStateLabel)
    controller.didMove(toParent: self)
    controller.view.clipsToBounds = true
  }

  func rebuildPageViewControllerIfNeeded() {
    guard configuration.interPageSpacing != appliedInterPageSpacing else { return }
    appliedInterPageSpacing = configuration.interPageSpacing
    let current = pageCount > 0 ? pageStore.controller(at: selectedIndex) : nil
    let replacement = Self.makePageViewController(interPageSpacing: configuration.interPageSpacing)
    replacement.dataSource = configuration.allowsSwipePaging ? self : nil
    replacement.delegate = self
    guard isViewLoaded else {
      pageViewController = replacement
      return
    }

    let oldPageViewController = pageViewController
    scrollView = nil
    didInstallPagingPanRequiresNavigationPopFailure = false
    installedNestedScrollPanRecognizers.removeAll()
    lastNestedScrollInstallIndex = nil

    pageViewController = replacement
    installPageViewControllerInHierarchy(pageViewController)
    rebindPageViewHorizontalConstraints()
    applyTabBarLayout()

    oldPageViewController.willMove(toParent: nil)
    oldPageViewController.view.removeFromSuperview()
    oldPageViewController.removeFromParent()

    if let current {
      let direction = Self.pageNavigationDirection(
        from: selectedIndex,
        to: selectedIndex,
        layoutDirection: view.effectiveUserInterfaceLayoutDirection
      )
      pageViewController.setViewControllers([current], direction: direction, animated: false)
    }

    attachScrollViewIfNeeded()
    updateSwipeEnabledForCurrentPage()
  }

  func detachPageChildren(from pageViewController: UIPageViewController) {
    for controller in pageViewController.children {
      controller.willMove(toParent: nil)
      controller.view.removeFromSuperview()
      controller.removeFromParent()
    }
  }

  func attachScrollViewIfNeeded() {
    guard scrollView == nil else { return }
    scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView
    scrollView?.delegate = self
    didInstallPagingPanRequiresNavigationPopFailure = false
    applyGesturePolicyToPagingScrollView()
    updateSwipeEnabledForCurrentPage()
    installNestedHorizontalScrollGestureRelationships()
  }

  func installInitialPage() {
    guard pageCount > 0 else { return }
    applyPageHostContent(animated: false)
    guard pageStore.controller(at: selectedIndex) != nil else { return }
    tabCoordinator.syncSettled(index: selectedIndex, animated: false)
    notifyWillDisplay(at: selectedIndex)
    publishDisplayedPage(at: selectedIndex, force: true)
  }

  func applyPageHostContent(animated: Bool = false) {
    guard isViewLoaded else { return }
    guard pageCount > 0, let current = pageStore.controller(at: selectedIndex) else {
      detachPageChildren(from: pageViewController)
      return
    }
    let direction = Self.pageNavigationDirection(from: selectedIndex, to: selectedIndex, layoutDirection: view.effectiveUserInterfaceLayoutDirection)
    pageViewController.setViewControllers([current], direction: direction, animated: animated)
  }

  func beginProgrammaticTransition(to target: Int, animated: Bool) {
    guard let targetController = pageStore.controller(at: target) else { return }
    if target == selectedIndex {
      cancelProgrammaticTransitionPipeline()
      settle(at: target, animatedTab: false)
      applyPageHostContent(animated: false)
      return
    }
    if pendingProgrammaticIndex == target { return }
    if pendingProgrammaticIndex != nil {
      queuedProgrammaticTarget = target
      queuedProgrammaticAnimated = animated
      return
    }
    notifyWillDisplay(at: target)
    let token = stateMachine.beginProgrammaticSwitch(from: selectedIndex, to: target)
    pendingProgrammaticIndex = target
    notifyPhase()
    let direction = Self.pageNavigationDirection(from: selectedIndex, to: target, layoutDirection: view.effectiveUserInterfaceLayoutDirection)
    pageViewController.setViewControllers([targetController], direction: direction, animated: animated) { [weak self] finished in
      guard let self else { return }
      if token != self.stateMachine.snapshot.transitionToken {
        self.applyPageHostContent(animated: false)
        return
      }
      guard finished || !animated else {
        self.stateMachine.interrupt()
        self.pendingDisplayIndices.remove(target)
        self.pendingProgrammaticIndex = nil
        self.applyPageHostContent(animated: false)
        self.notifyPhase()
        self.drainProgrammaticTransitionQueue()
        return
      }
      self.pendingProgrammaticIndex = nil
      self.settle(at: target, animatedTab: animated)
      self.drainProgrammaticTransitionQueue()
    }
  }

  func cancelProgrammaticTransitionPipeline() {
    let hadPipelineWork = pendingProgrammaticIndex != nil || queuedProgrammaticTarget != nil
    if let pending = pendingProgrammaticIndex {
      pendingDisplayIndices.remove(pending)
    }
    pendingProgrammaticIndex = nil
    queuedProgrammaticTarget = nil
    if hadPipelineWork { _ = stateMachine.invalidateTransitionToken() }
  }

  static func pageNavigationDirection(from: Int, to: Int, layoutDirection: UIUserInterfaceLayoutDirection) -> UIPageViewController.NavigationDirection {
    let forward = to > from
    switch layoutDirection {
    case .rightToLeft: return forward ? .reverse : .forward
    case .leftToRight: return forward ? .forward : .reverse
    @unknown default: return forward ? .forward : .reverse
    }
  }

  func drainProgrammaticTransitionQueue() {
    guard let next = queuedProgrammaticTarget else { return }
    queuedProgrammaticTarget = nil
    let nextAnimated = queuedProgrammaticAnimated
    guard next != selectedIndex else { return }
    beginProgrammaticTransition(to: next, animated: nextAnimated)
  }

  func settle(at index: Int, animatedTab: Bool) {
    let previousIndex = selectedIndex
    if previousIndex != index, let previousController = pageStore.cachedController(at: previousIndex) {
      notifyEndDisplaying(previousController, at: previousIndex)
    }
    notifyWillDisplay(at: index)
    selectedIndex = index
    stateMachine.settle(at: index)
    tabCoordinator.syncSettled(index: index, animated: animatedTab)
    preloadAndCompact(at: index)
    updateSwipeEnabledForCurrentPage()
    installNestedHorizontalScrollGestureRelationships()
    delegate?.pagingController(self, didSettleAt: index)
    publishDisplayedPage(at: index)
    if UIAccessibility.isVoiceOverRunning {
      let currentItem = tabBar.visibleItems[safe: index]
      UIAccessibility.post(notification: .announcement, argument: currentItem?.accessibilityLabel ?? currentItem?.titleText ?? "\(index + 1)")
    }
    notifyPhase()
  }

  func notifyWillDisplay(at index: Int) {
    guard let controller = pageStore.cachedController(at: index) ?? pageStore.controller(at: index) else { return }
    guard !displayedPageIndices.contains(index), !pendingDisplayIndices.contains(index) else { return }
    pendingDisplayIndices.insert(index)
    delegate?.pagingController(self, willDisplayPage: controller, at: index)
  }

  func publishDisplayedPage(at index: Int, force: Bool = false) {
    guard force || index != lastDisplayedIndex else { return }
    guard let controller = pageStore.controller(at: index) else { return }
    lastDisplayedIndex = index
    pendingDisplayIndices.remove(index)
    displayedPageIndices.insert(index)
    delegate?.pagingController(self, didDisplayPage: controller, at: index)
  }

  func notifyEndDisplaying(_ controller: UIViewController, at index: Int) {
    guard displayedPageIndices.contains(index) || pendingDisplayIndices.contains(index) else { return }
    pendingDisplayIndices.remove(index)
    displayedPageIndices.remove(index)
    if lastDisplayedIndex == index { lastDisplayedIndex = nil }
    delegate?.pagingController(self, didEndDisplayingPage: controller, at: index)
  }

  func preloadAndCompact(at index: Int) {
    pageStore.preload(around: index, range: configuration.preloadRange)
    pageStore.compactCache(selectedIndex: index, retention: configuration.retentionPolicy) { [weak self] evictedIndex, controller in
      self?.notifyEndDisplaying(controller, at: evictedIndex)
    }
  }

  func applyConfiguration() {
    tabCoordinator.applyPageSwitchGate(configuration.pageSwitchGate, scope: configuration.pageSwitchGateScope)
    rebuildPageViewControllerIfNeeded()
    updateTabBarHeightIfNeeded()
    if isViewLoaded { applyTabBarLayout() }
    if pageCount == 0 {
      pageViewController.dataSource = nil
      scrollView?.isScrollEnabled = false
    } else {
      pageViewController.dataSource = configuration.allowsSwipePaging ? self : nil
      updateSwipeEnabledForCurrentPage()
    }
    applyGesturePolicyToPagingScrollView()
    installNestedHorizontalScrollGestureRelationships()
    updateEmptyStateVisibility()
    if configuration.tabAlignment == .alwaysCenter {
      var layout = tabBar.configuration.layout
      layout.selectionScrollPosition = .center
      tabBar.configuration.layout = layout
    }
    if isViewLoaded, pageCount > 0 {
      applyPageHostContent(animated: false)
    }
  }

  func updateSwipeEnabledForCurrentPage() {
    scrollView?.isScrollEnabled = isSwipePagingEnabled
  }

  func resolvedTabBarHeight() -> CGFloat {
    switch configuration.tabBarHeightPolicy {
    case .fixed(let height): return max(36, height)
    case .automatic: return max(36, tabBar.intrinsicContentSize.height)
    }
  }

  func updateTabBarHeightIfNeeded() {
    tabHeightConstraint?.constant = resolvedTabBarHeight()
  }

  func notifyPhase() {
    delegate?.pagingController(self, didChangePhase: stateMachine.snapshot.phase)
    notifyCombinedTransition(progress: stateMachine.snapshot.progress)
  }

  func notifyCombinedTransition(progress: CGFloat) {
    delegate?.pagingController(self, didUpdateCombinedTransition: tabBar.switchPhase, pagingPhase: stateMachine.snapshot.phase, progress: progress)
  }

  func applyGesturePolicyToPagingScrollView() {
    guard let scrollView else { return }
    switch configuration.gesturePolicy {
    case .preferNavigationBackGesture:
      guard !didInstallPagingPanRequiresNavigationPopFailure,
            let pop = nearestNavigationInteractivePopGestureRecognizer() else { return }
      scrollView.panGestureRecognizer.require(toFail: pop)
      didInstallPagingPanRequiresNavigationPopFailure = true
    case .exclusive:
      break
    }
  }

  func installNestedHorizontalScrollGestureRelationships() {
    guard configuration.nestedHorizontalScrollPolicy == .preferNestedHorizontalScroll,
          let pagingPan = scrollView?.panGestureRecognizer,
          let pageView = pageStore.cachedController(at: selectedIndex)?.view else { return }

    if lastNestedScrollInstallIndex != selectedIndex {
      installedNestedScrollPanRecognizers.removeAll()
      lastNestedScrollInstallIndex = selectedIndex
    }

    for nestedScrollView in FKPagingScrollUtilities.horizontalScrollViews(in: pageView) {
      let nestedPan = nestedScrollView.panGestureRecognizer
      let token = ObjectIdentifier(nestedPan)
      guard !installedNestedScrollPanRecognizers.contains(token) else { continue }
      pagingPan.require(toFail: nestedPan)
      installedNestedScrollPanRecognizers.insert(token)
    }
  }

  func nearestNavigationInteractivePopGestureRecognizer() -> UIGestureRecognizer? {
    var controller: UIViewController? = self
    while let current = controller {
      if let pop = current.navigationController?.interactivePopGestureRecognizer { return pop }
      controller = current.parent
    }
    return nil
  }

  func scrollCurrentPageToTop() {
    guard let rootView = pageStore.cachedController(at: selectedIndex)?.view else { return }
    FKPagingScrollUtilities.scrollPageToTop(in: rootView)
  }
}
