import UIKit

/// A high-level paging container that keeps `FKTabBar` and page content synchronized.
///
/// `FKPagingController` centralizes bidirectional sync, transition state, gesture conflict handling,
/// and memory-aware page retention. It is designed for production scenarios where rapid taps,
/// interactive swipes, and dynamic data updates may happen concurrently.
@MainActor
public final class FKPagingController: UIViewController {
  public weak var delegate: FKPagingControllerDelegate?

  /// Embedded tab header used as the primary page switch affordance.
  public let tabBar: FKTabBar
  /// Current selected page index.
  public private(set) var selectedIndex: Int
  /// Current state snapshot.
  public var stateSnapshot: FKPagingStateSnapshot { stateMachine.snapshot }
  /// Current effective page count.
  public var pageCount: Int { pageStore.pageCount }

  /// Runtime configuration.
  ///
  /// Updating this value applies gesture and layout settings immediately.
  public var configuration: FKPagingConfiguration {
    didSet {
      applyConfiguration()
    }
  }

  private let pageViewController: UIPageViewController
  private let stateMachine: FKPagingStateMachine
  private let pageStore: FKPagingPageStore
  private let tabCoordinator = FKPagingTabBarCoordinator()
  private let gestureCoordinator = FKPagingGestureCoordinator()

  private var transitionToken: Int = 0
  private var pendingProgrammaticIndex: Int?
  private var scrollView: UIScrollView?
  private var tabHeightConstraint: NSLayoutConstraint?

  /// Creates a paging controller with eagerly provided child view controllers.
  ///
  /// - Important: `tabs.count` should match the number of visible pages.
  public init(
    tabs: [FKTabBarItem],
    viewControllers: [UIViewController],
    selectedIndex: Int = 0,
    tabAppearance: FKTabBarAppearance? = nil,
    tabLayoutOptions: FKTabBarLayoutConfiguration? = nil,
    tabAnimationOptions: FKTabBarAnimationConfiguration? = nil,
    configuration: FKPagingConfiguration = FKPagingConfiguration()
  ) {
    let safeCount = min(tabs.filter { !$0.isHidden }.count, viewControllers.count)
    let effectiveTabs = Array(tabs.prefix(safeCount))
    self.pageStore = FKPagingPageStore(viewControllers: Array(viewControllers.prefix(safeCount)))
    self.selectedIndex = max(0, min(selectedIndex, max(0, safeCount - 1)))
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

  /// Creates a paging controller with lazily created child view controllers.
  ///
  /// The lazy variant is recommended for large tab sets because it defers expensive page construction.
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
    let safeCount = min(tabs.filter { !$0.isHidden }.count, max(0, pageCount))
    let effectiveTabs = Array(tabs.prefix(safeCount))
    self.pageStore = FKPagingPageStore(pageCount: safeCount, provider: pageProvider)
    self.selectedIndex = max(0, min(selectedIndex, max(0, safeCount - 1)))
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
    applyConfiguration()
    preloadAndCompact(at: selectedIndex)
  }

  public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    coordinator.animate(alongsideTransition: { [weak self] _ in
      self?.tabBar.realignSelection(animated: false)
    })
  }

  /// Programmatically switches to the requested page.
  ///
  /// Newer requests supersede older unfinished requests using transition tokens.
  public func setSelectedIndex(_ index: Int, animated: Bool = true) {
    guard pageCount > 0 else { return }
    let target = min(max(0, index), pageCount - 1)
    guard target != selectedIndex else {
      tabCoordinator.syncSettled(index: target, animated: false)
      return
    }
    beginProgrammaticTransition(to: target, animated: animated)
  }

  /// Replaces tabs and pages, preserving selection when possible.
  ///
  /// If current selection is out of bounds after update, it is clamped.
  public func setContent(
    tabs: [FKTabBarItem],
    viewControllers: [UIViewController],
    selectedIndex: Int? = nil
  ) {
    let safeCount = min(tabs.filter { !$0.isHidden }.count, viewControllers.count)
    let effectiveTabs = Array(tabs.prefix(safeCount))
    pageStore.reset(pageCount: safeCount, provider: nil, controllers: Array(viewControllers.prefix(safeCount)))
    tabBar.reload(items: effectiveTabs, updatePolicy: .preserveSelection)
    let target = selectedIndex ?? min(self.selectedIndex, max(0, safeCount - 1))
    self.selectedIndex = min(max(0, target), max(0, safeCount - 1))
    stateMachine.settle(at: self.selectedIndex)
    if let current = pageStore.controller(at: self.selectedIndex) {
      pageViewController.setViewControllers([current], direction: .forward, animated: false)
    }
    tabCoordinator.syncSettled(index: self.selectedIndex, animated: false)
    preloadAndCompact(at: self.selectedIndex)
    notifyPhase()
  }
}

@MainActor
extension FKPagingController: FKPagingTabBarCoordinatorDelegate {
  func pagingCoordinatorDidRequestSwitch(to index: Int, animated: Bool) {
    setSelectedIndex(index, animated: animated)
  }
}

@MainActor
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
      notifyPhase()
      return
    }
    guard completed,
          let current = pageViewController.viewControllers?.first,
          let index = pageStore.index(of: current) else {
      stateMachine.settle(at: selectedIndex)
      notifyPhase()
      return
    }
    settle(at: index, animatedTab: true)
  }
}

@MainActor
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
    let delta = scrollView.contentOffset.x - width
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

    scrollView = pageViewController.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView
    scrollView?.delegate = self
    scrollView?.panGestureRecognizer.delegate = gestureCoordinator
  }

  func installInitialPage() {
    guard let first = pageStore.controller(at: selectedIndex) else { return }
    pageViewController.setViewControllers([first], direction: .forward, animated: false)
    tabCoordinator.syncSettled(index: selectedIndex, animated: false)
  }

  func beginProgrammaticTransition(to target: Int, animated: Bool) {
    guard let targetController = pageStore.controller(at: target) else { return }
    if target == selectedIndex {
      settle(at: target, animatedTab: false)
      return
    }
    transitionToken = stateMachine.beginProgrammaticSwitch(from: selectedIndex, to: target)
    pendingProgrammaticIndex = target
    notifyPhase()
    let token = transitionToken
    let direction: UIPageViewController.NavigationDirection = target > selectedIndex ? .forward : .reverse
    pageViewController.setViewControllers([targetController], direction: direction, animated: animated) { [weak self] finished in
      guard let self else { return }
      guard token == self.transitionToken else { return }
      guard finished || !animated else {
        self.stateMachine.interrupt()
        self.pendingProgrammaticIndex = nil
        self.notifyPhase()
        return
      }
      self.pendingProgrammaticIndex = nil
      self.settle(at: target, animatedTab: animated)
    }
  }

  func settle(at index: Int, animatedTab: Bool) {
    selectedIndex = index
    stateMachine.settle(at: index)
    tabCoordinator.syncSettled(index: index, animated: animatedTab)
    preloadAndCompact(at: index)
    delegate?.pagingController(self, didSettleAt: index)
    if UIAccessibility.isVoiceOverRunning {
      let currentItem = tabBar.items[safe: index]
      let spoken = currentItem?.accessibilityLabel ?? currentItem?.title ?? "\(index + 1)"
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
    pageViewController.dataSource = configuration.allowsSwipePaging ? self : nil
    scrollView?.isScrollEnabled = configuration.allowsSwipePaging
    gestureCoordinator.policy = configuration.gesturePolicy
    if configuration.tabAlignment == .alwaysCenter {
      var layout = tabBar.layoutConfiguration ?? FKTabBarLayoutConfiguration()
      layout.selectionScrollPosition = .center
      tabBar.layoutConfiguration = layout
    }
  }

  func notifyPhase() {
    delegate?.pagingController(self, didChangePhase: stateMachine.snapshot.phase)
  }
}
