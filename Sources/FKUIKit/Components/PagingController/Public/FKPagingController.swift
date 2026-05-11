import UIKit

/// Hosts a ``FKTabBar`` above a `UIPageViewController`-powered pager with bidirectional synchronization.
///
/// ## Responsibilities
/// - Keeps tab taps and horizontal paging aligned, including interactive indicator progress.
/// - Tracks transition phases for analytics or coordinated animations via ``FKPagingControllerDelegate``.
/// - Optionally lazily constructs pages with configurable caching for large tab sets.
///
/// ## Topics
/// - **Paging**: ``setSelectedIndex(_:animated:)``, swipe gestures controlled by ``FKPagingConfiguration/allowsSwipePaging``.
/// - **Content updates**: ``setContent(tabs:viewControllers:selectedIndex:)`` and ``setContent(tabs:pageCount:pageProvider:selectedIndex:)``.
@MainActor
public final class FKPagingController: UIViewController {
  public weak var delegate: FKPagingControllerDelegate?

  /// Embedded tab strip driving selection affordances and accessibility traits.
  public let tabBar: FKTabBar

  /// Currently selected page index (last settled value during transitions).
  public private(set) var selectedIndex: Int

  /// Latest structured snapshot from the internal state machine.
  public var stateSnapshot: FKPagingStateSnapshot { stateMachine.snapshot }

  /// `true` while a drag, deceleration, or programmatic animation has not finished settling.
  public var isTransitionActive: Bool {
    switch stateMachine.snapshot.phase {
    case .idle, .interrupted:
      return false
    case .dragging, .settling, .programmaticSwitch:
      return true
    }
  }

  /// Number of logical pages (tabs).
  public var pageCount: Int { pageStore.pageCount }

  /// Runtime tuning for swipe behavior, caching, layout, and gestures.
  public var configuration: FKPagingConfiguration {
    didSet { applyConfiguration() }
  }

  private let pageViewController: UIPageViewController
  private let stateMachine: FKPagingStateMachine
  private let pageStore: FKPagingPageStore
  private let tabCoordinator = FKPagingTabBarCoordinator()

  private var pendingProgrammaticIndex: Int?
  /// Latest target requested while a programmatic ``UIPageViewController`` transition is still in flight (last write wins).
  private var queuedProgrammaticTarget: Int?
  private var queuedProgrammaticAnimated: Bool = true
  private var scrollView: UIScrollView?
  private var tabHeightConstraint: NSLayoutConstraint?
  /// Ensures we only call ``UIGestureRecognizer/require(toFail:)`` once per discovered paging scroll view.
  private var didInstallPagingPanRequiresNavigationPopFailure = false

  /// Builds the pager from eagerly supplied view controllers (recommended for small page counts).
  public init(
    tabs: [FKTabBarItem],
    viewControllers: [UIViewController],
    selectedIndex: Int = 0,
    tabAppearance: FKTabBarAppearance? = nil,
    tabLayoutOptions: FKTabBarLayoutConfiguration? = nil,
    tabAnimationOptions: FKTabBarAnimationConfiguration? = nil,
    configuration: FKPagingConfiguration = FKPagingConfiguration()
  ) {
    let hiddenFilteredTabs = tabs.filter { !$0.isHidden }
    let safeCount = min(hiddenFilteredTabs.count, viewControllers.count)
    let effectiveTabs = Array(hiddenFilteredTabs.prefix(safeCount))
    self.pageStore = FKPagingPageStore(viewControllers: Array(viewControllers.prefix(safeCount)))
    self.selectedIndex = safeCount > 0 ? max(0, min(selectedIndex, safeCount - 1)) : 0
    self.stateMachine = FKPagingStateMachine(initialIndex: self.selectedIndex)
    self.configuration = configuration
    self.tabBar = FKTabBar(
      items: effectiveTabs,
      selectedIndex: self.selectedIndex,
      appearance: tabAppearance,
      layoutConfiguration: tabLayoutOptions,
      animationConfiguration: tabAnimationOptions
    )
    self.pageViewController = UIPageViewController(
      transitionStyle: .scroll,
      navigationOrientation: .horizontal,
      options: [.interPageSpacing: 0]
    )
    super.init(nibName: nil, bundle: nil)
    commonInit()
  }

  /// Builds the pager using lazy page construction (recommended for heavier pages).
  public init(
    tabs: [FKTabBarItem],
    pageCount: Int,
    pageProvider: @escaping (Int) -> UIViewController,
    selectedIndex: Int = 0,
    tabAppearance: FKTabBarAppearance? = nil,
    tabLayoutOptions: FKTabBarLayoutConfiguration? = nil,
    tabAnimationOptions: FKTabBarAnimationConfiguration? = nil,
    configuration: FKPagingConfiguration = FKPagingConfiguration()
  ) {
    let hiddenFilteredTabs = tabs.filter { !$0.isHidden }
    let safeCount = min(hiddenFilteredTabs.count, max(0, pageCount))
    let effectiveTabs = Array(hiddenFilteredTabs.prefix(safeCount))
    self.pageStore = FKPagingPageStore(pageCount: safeCount, provider: pageProvider)
    self.selectedIndex = safeCount > 0 ? max(0, min(selectedIndex, safeCount - 1)) : 0
    self.stateMachine = FKPagingStateMachine(initialIndex: self.selectedIndex)
    self.configuration = configuration
    self.tabBar = FKTabBar(
      items: effectiveTabs,
      selectedIndex: self.selectedIndex,
      appearance: tabAppearance,
      layoutConfiguration: tabLayoutOptions,
      animationConfiguration: tabAnimationOptions
    )
    self.pageViewController = UIPageViewController(
      transitionStyle: .scroll,
      navigationOrientation: .horizontal,
      options: [.interPageSpacing: 0]
    )
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
    setupHierarchy()
    installInitialPage()
    preloadAndCompact(at: selectedIndex)
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    attachScrollViewIfNeeded()
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.tabBar.realignSelection(animated: false)
    })
  }

  /// Selects a page programmatically. Overlapping animated requests are queued and applied sequentially.
  public func setSelectedIndex(_ index: Int, animated: Bool = true) {
    guard pageCount > 0 else { return }
    let target = min(max(0, index), pageCount - 1)
    guard target != selectedIndex else {
      tabCoordinator.syncSettled(index: target, animated: false)
      return
    }
    beginProgrammaticTransition(to: target, animated: animated)
  }

  /// Replaces tabs and synchronous pages, preserving selection when possible (clamped when out of range).
  public func setContent(
    tabs: [FKTabBarItem],
    viewControllers: [UIViewController],
    selectedIndex: Int? = nil
  ) {
    let hiddenFilteredTabs = tabs.filter { !$0.isHidden }
    let safeCount = min(hiddenFilteredTabs.count, viewControllers.count)
    let effectiveTabs = Array(hiddenFilteredTabs.prefix(safeCount))
    cancelProgrammaticTransitionPipeline()
    pageStore.reset(pageCount: safeCount, provider: nil, controllers: Array(viewControllers.prefix(safeCount)))
    tabBar.reload(items: effectiveTabs, updatePolicy: .preserveSelection)
    let target = selectedIndex ?? min(self.selectedIndex, max(0, safeCount - 1))
    self.selectedIndex = safeCount > 0 ? min(max(0, target), safeCount - 1) : 0
    stateMachine.settle(at: self.selectedIndex)
    applyPageHostContent()
    tabCoordinator.syncSettled(index: self.selectedIndex, animated: false)
    preloadAndCompact(at: self.selectedIndex)
    notifyPhase()
  }

  /// Replaces tabs and switches to lazy page provisioning (drops eager instances held by the previous mode).
  public func setContent(
    tabs: [FKTabBarItem],
    pageCount: Int,
    pageProvider: @escaping (Int) -> UIViewController,
    selectedIndex: Int? = nil
  ) {
    let hiddenFilteredTabs = tabs.filter { !$0.isHidden }
    let safeCount = min(hiddenFilteredTabs.count, max(0, pageCount))
    let effectiveTabs = Array(hiddenFilteredTabs.prefix(safeCount))
    cancelProgrammaticTransitionPipeline()
    pageStore.reset(pageCount: safeCount, provider: pageProvider, controllers: [])
    tabBar.reload(items: effectiveTabs, updatePolicy: .preserveSelection)
    let target = selectedIndex ?? min(self.selectedIndex, max(0, safeCount - 1))
    self.selectedIndex = safeCount > 0 ? min(max(0, target), safeCount - 1) : 0
    stateMachine.settle(at: self.selectedIndex)
    applyPageHostContent()
    tabCoordinator.syncSettled(index: self.selectedIndex, animated: false)
    preloadAndCompact(at: self.selectedIndex)
    notifyPhase()
  }
}

// MARK: - Tab coordinator

extension FKPagingController: FKPagingTabBarCoordinatorDelegate {
  func pagingCoordinatorDidRequestSwitch(to index: Int, animated: Bool) {
    setSelectedIndex(index, animated: animated)
  }
}

// MARK: - UIPageViewController

extension FKPagingController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
  public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
    guard let index = pageStore.index(of: viewController), index > 0 else { return nil }
    return pageStore.controller(at: index - 1)
  }

  public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
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
      stateMachine.interrupt()
      applyPageHostContent()
      notifyPhase()
      return
    }
    guard completed,
          let current = pageViewController.viewControllers?.first,
          let index = pageStore.index(of: current) else {
      stateMachine.settle(at: selectedIndex)
      applyPageHostContent()
      notifyPhase()
      return
    }
    settle(at: index, animatedTab: true)
  }
}

// MARK: - Interactive scrolling

extension FKPagingController: UIScrollViewDelegate {
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    guard configuration.allowsSwipePaging else { return }
    stateMachine.beginDragging(from: selectedIndex, to: selectedIndex)
    notifyPhase()
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard configuration.allowsSwipePaging else { return }
    guard pendingProgrammaticIndex == nil else { return }
    guard pageCount > 1 else { return }
    let width = max(1, scrollView.bounds.width)
    var delta = scrollView.contentOffset.x - width
    if view.effectiveUserInterfaceLayoutDirection == .rightToLeft {
      delta = -delta
    }
    guard abs(delta) > 0.0001 else { return }
    let direction = delta > 0 ? 1 : -1
    let from = selectedIndex
    let to = from + direction
    guard to >= 0, to < pageCount else { return }
    let progress = min(1, abs(delta) / width)
    stateMachine.updateDraggingProgress(progress, from: from, to: to)
    tabCoordinator.syncProgress(from: from, to: to, progress: progress)
    delegate?.pagingController(self, didUpdateProgress: progress, from: from, to: to)
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
  func commonInit() {
    tabCoordinator.delegate = self
    tabCoordinator.bind(tabBar: tabBar)
    pageViewController.dataSource = self
    pageViewController.delegate = self
  }

  func setupHierarchy() {
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    addChild(pageViewController)
    pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabBar)
    view.addSubview(pageViewController.view)
    pageViewController.didMove(toParent: self)
    pageViewController.view.clipsToBounds = true

    tabHeightConstraint = tabBar.heightAnchor.constraint(equalToConstant: configuration.tabBarHeight)
    tabHeightConstraint?.isActive = true

    NSLayoutConstraint.activate([
      tabBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pageViewController.view.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
      pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])

    attachScrollViewIfNeeded()
  }

  func attachScrollViewIfNeeded() {
    guard scrollView == nil else { return }
    let found = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView
    scrollView = found
    scrollView?.delegate = self
    didInstallPagingPanRequiresNavigationPopFailure = false
    applyGesturePolicyToPagingScrollView()
  }

  func installInitialPage() {
    applyPageHostContent()
    guard pageCount > 0, pageStore.controller(at: selectedIndex) != nil else { return }
    tabCoordinator.syncSettled(index: selectedIndex, animated: false)
  }

  /// Clears or restores hosted controllers whenever page count or storage mode changes.
  func applyPageHostContent() {
    applyConfiguration()
    guard pageCount > 0, let current = pageStore.controller(at: selectedIndex) else {
      pageViewController.setViewControllers(nil, direction: .forward, animated: false, completion: nil)
      return
    }
    let direction = Self.pageNavigationDirection(
      from: selectedIndex,
      to: selectedIndex,
      layoutDirection: view.effectiveUserInterfaceLayoutDirection
    )
    pageViewController.setViewControllers([current], direction: direction, animated: false, completion: nil)
  }

  func beginProgrammaticTransition(to target: Int, animated: Bool) {
    guard let targetController = pageStore.controller(at: target) else { return }
    if target == selectedIndex {
      cancelProgrammaticTransitionPipeline()
      settle(at: target, animatedTab: false)
      applyPageHostContent()
      return
    }
    if pendingProgrammaticIndex == target {
      return
    }
    // UIPageViewController asserts if `setViewControllers` is invoked again before an animated transition settles.
    if pendingProgrammaticIndex != nil {
      queuedProgrammaticTarget = target
      queuedProgrammaticAnimated = animated
      return
    }
    let token = stateMachine.beginProgrammaticSwitch(from: selectedIndex, to: target)
    pendingProgrammaticIndex = target
    notifyPhase()
    let direction = Self.pageNavigationDirection(
      from: selectedIndex,
      to: target,
      layoutDirection: view.effectiveUserInterfaceLayoutDirection
    )
    pageViewController.setViewControllers([targetController], direction: direction, animated: animated) { [weak self] finished in
      guard let self else { return }
      if token != self.stateMachine.snapshot.transitionToken {
        self.applyPageHostContent()
        return
      }
      guard finished || !animated else {
        self.stateMachine.interrupt()
        self.pendingProgrammaticIndex = nil
        self.applyPageHostContent()
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
    pendingProgrammaticIndex = nil
    queuedProgrammaticTarget = nil
    if hadPipelineWork {
      _ = stateMachine.invalidateTransitionToken()
    }
  }

  /// Maps logical forward/reverse paging to `UIPageViewController.NavigationDirection` under RTL layout.
  static func pageNavigationDirection(
    from: Int,
    to: Int,
    layoutDirection: UIUserInterfaceLayoutDirection
  ) -> UIPageViewController.NavigationDirection {
    let forward = to > from
    switch layoutDirection {
    case .rightToLeft:
      return forward ? .reverse : .forward
    case .leftToRight:
      return forward ? .forward : .reverse
    @unknown default:
      return forward ? .forward : .reverse
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
    selectedIndex = index
    stateMachine.settle(at: index)
    tabCoordinator.syncSettled(index: index, animated: animatedTab)
    preloadAndCompact(at: index)
    delegate?.pagingController(self, didSettleAt: index)
    if UIAccessibility.isVoiceOverRunning {
      let currentItem = tabBar.items[safe: index]
      let spoken = currentItem?.accessibilityLabel ?? currentItem?.titleText ?? "\(index + 1)"
      UIAccessibility.post(notification: .announcement, argument: spoken)
    }
    notifyPhase()
  }

  func preloadAndCompact(at index: Int) {
    pageStore.preload(around: index, range: configuration.preloadRange)
    pageStore.compactCache(selectedIndex: index, retention: configuration.retentionPolicy)
  }

  func applyConfiguration() {
    tabHeightConstraint?.constant = configuration.tabBarHeight
    if pageCount == 0 {
      pageViewController.dataSource = nil
      scrollView?.isScrollEnabled = false
    } else {
      pageViewController.dataSource = configuration.allowsSwipePaging ? self : nil
      scrollView?.isScrollEnabled = configuration.allowsSwipePaging
    }
    applyGesturePolicyToPagingScrollView()
    if configuration.tabAlignment == .alwaysCenter {
      var layout = tabBar.layoutConfiguration ?? FKTabBarLayoutConfiguration()
      layout.selectionScrollPosition = .center
      tabBar.layoutConfiguration = layout
    }
  }

  func notifyPhase() {
    delegate?.pagingController(self, didChangePhase: stateMachine.snapshot.phase)
  }

  /// UIKit forbids assigning a custom object as ``UIScrollView/panGestureRecognizer`` delegate; use `require(toFail:)` instead.
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

  func nearestNavigationInteractivePopGestureRecognizer() -> UIGestureRecognizer? {
    var controller: UIViewController? = self
    while let current = controller {
      if let pop = current.navigationController?.interactivePopGestureRecognizer {
        return pop
      }
      controller = current.parent
    }
    return nil
  }
}
