import UIKit

/// Installs ``FKTabBar`` for ``FKPagingTabBarPlacement`` and maintains page-host constraints.
@MainActor
final class FKPagingTabBarPlacementCoordinator {
  private struct ContentLayoutConstraints {
    var tabTop: NSLayoutConstraint?
    var tabBottom: NSLayoutConstraint?
    var pageTop: NSLayoutConstraint?
    var pageBottom: NSLayoutConstraint?
  }

  private weak var pagingView: UIView?
  private weak var pageHostView: UIView?
  private weak var pagingViewController: UIViewController?
  weak var tabBarNavigationHost: UIViewController?

  let tabBar: FKTabBar

  private var tabHeightConstraint: NSLayoutConstraint?
  private var contentLayoutConstraints = ContentLayoutConstraints()

  private weak var navigationTitleViewHost: UIViewController?
  private weak var previousTitleView: UIView?
  private var savedHostTitle: String?

  init(tabBar: FKTabBar, pagingViewController: UIViewController) {
    self.tabBar = tabBar
    self.pagingViewController = pagingViewController
    self.pagingView = pagingViewController.view
  }

  func bind(pageHostView: UIView) {
    self.pageHostView = pageHostView
  }

  func apply(
    placement: FKPagingTabBarPlacement,
    tabBarHeightPolicy: FKPagingTabBarHeightPolicy,
    showsEmptyState: Bool
  ) {
    syncTabBarHostingContext(for: placement)

    switch placement {
    case .contentArea(let position):
      teardownNavigationBarTitleViewIfInstalled()
      installTabBarInPagingView()
      applyContentAreaLayout(position: position, tabBarHeightPolicy: tabBarHeightPolicy)
    case .navigationBar(let options):
      removeTabBarFromPagingView()
      applyNavigationBarPlacement(options: options, tabBarHeightPolicy: tabBarHeightPolicy)
    case .external:
      teardownNavigationBarTitleViewIfInstalled()
      removeTabBarFromPagingView()
      applyPageHostOnlyLayout()
    }
    tabBar.isHidden = showsEmptyState
    pagingView?.setNeedsLayout()
  }

  func resolvedTabBarHeight(
    placement: FKPagingTabBarPlacement,
    tabBarHeightPolicy: FKPagingTabBarHeightPolicy
  ) -> CGFloat {
    switch placement {
    case .navigationBar(let options):
      switch tabBarHeightPolicy {
      case .fixed(let height):
        return min(44, max(28, height))
      case .automatic:
        return min(44, max(28, max(tabBar.intrinsicContentSize.height, options.preferredHeight)))
      }
    case .contentArea, .external:
      switch tabBarHeightPolicy {
      case .fixed(let height): return max(36, height)
      case .automatic: return max(36, tabBar.intrinsicContentSize.height)
      }
    }
  }

  func updateTabBarHeightIfNeeded(
    placement: FKPagingTabBarPlacement,
    tabBarHeightPolicy: FKPagingTabBarHeightPolicy
  ) {
    guard case .contentArea = placement else { return }
    tabHeightConstraint?.constant = resolvedTabBarHeight(placement: placement, tabBarHeightPolicy: tabBarHeightPolicy)
  }

  func updateNavigationBarTitleViewLayoutIfNeeded(
    placement: FKPagingTabBarPlacement,
    tabBarHeightPolicy: FKPagingTabBarHeightPolicy
  ) {
    guard case .navigationBar(let options) = placement else { return }
    guard let host = navigationTitleViewHost, host.navigationItem.titleView === tabBar else { return }

    let titleSlotWidth = navigationBarTitleSlotWidth(for: host, options: options)
    let barHeight = resolvedTabBarHeight(
      placement: .navigationBar(options),
      tabBarHeightPolicy: tabBarHeightPolicy
    )
    let fittingSize = tabBar.sizeThatFits(CGSize(width: titleSlotWidth, height: barHeight))
    guard fittingSize != tabBar.bounds.size else { return }

    tabBar.bounds = CGRect(origin: .zero, size: fittingSize)
    tabBar.setNeedsLayout()
    host.navigationItem.titleView?.setNeedsLayout()
    host.navigationController?.navigationBar.setNeedsLayout()
  }

  func teardownNavigationBarTitleViewIfInstalled() {
    guard let host = navigationTitleViewHost else { return }
    if host.navigationItem.titleView === tabBar {
      host.navigationItem.titleView = previousTitleView
    }
    if let savedHostTitle {
      host.navigationItem.title = savedHostTitle
      self.savedHostTitle = nil
    }
    previousTitleView = nil
    navigationTitleViewHost = nil
  }

  // MARK: - Private

  private func syncTabBarHostingContext(for placement: FKPagingTabBarPlacement) {
    let context: FKTabBarHostingContext
    switch placement {
    case .navigationBar:
      context = .navigationBarTitleView
    case .contentArea, .external:
      context = .standalone
    }

    var config = tabBar.configuration
    guard config.layout.hostingContext != context else { return }
    config.layout.hostingContext = context
    tabBar.applyConfiguration(config)
  }

  private func installTabBarInPagingView() {
    guard let pagingView else { return }
    guard tabBar.superview !== pagingView else {
      tabBar.translatesAutoresizingMaskIntoConstraints = false
      return
    }
    tabBar.removeFromSuperview()
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    pagingView.addSubview(tabBar)
    if tabHeightConstraint == nil {
      tabHeightConstraint = tabBar.heightAnchor.constraint(equalToConstant: 48)
      tabHeightConstraint?.isActive = true
      NSLayoutConstraint.activate([
        tabBar.leadingAnchor.constraint(equalTo: pagingView.leadingAnchor),
        tabBar.trailingAnchor.constraint(equalTo: pagingView.trailingAnchor),
      ])
    }
  }

  private func removeTabBarFromPagingView() {
    guard let pagingView, tabBar.superview === pagingView else { return }
    tabBar.removeFromSuperview()
    deactivateContentAreaTabConstraints()
  }

  private func deactivateContentAreaTabConstraints() {
    contentLayoutConstraints.tabTop?.isActive = false
    contentLayoutConstraints.tabBottom?.isActive = false
    contentLayoutConstraints.tabTop = nil
    contentLayoutConstraints.tabBottom = nil
  }

  private func applyContentAreaLayout(position: FKPagingTabBarPosition, tabBarHeightPolicy: FKPagingTabBarHeightPolicy) {
    guard let pagingView, let pageHostView else { return }
    tabHeightConstraint?.constant = resolvedTabBarHeight(
      placement: .contentArea(position),
      tabBarHeightPolicy: tabBarHeightPolicy
    )

    contentLayoutConstraints.pageTop?.isActive = false
    contentLayoutConstraints.pageBottom?.isActive = false
    contentLayoutConstraints.tabTop?.isActive = false
    contentLayoutConstraints.tabBottom?.isActive = false

    switch position {
    case .top:
      contentLayoutConstraints.tabTop = tabBar.topAnchor.constraint(equalTo: pagingView.safeAreaLayoutGuide.topAnchor)
      contentLayoutConstraints.pageTop = pageHostView.topAnchor.constraint(equalTo: tabBar.bottomAnchor)
      contentLayoutConstraints.pageBottom = pageHostView.bottomAnchor.constraint(equalTo: pagingView.bottomAnchor)
    case .bottom:
      contentLayoutConstraints.pageTop = pageHostView.topAnchor.constraint(equalTo: pagingView.safeAreaLayoutGuide.topAnchor)
      contentLayoutConstraints.pageBottom = pageHostView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
      contentLayoutConstraints.tabBottom = tabBar.bottomAnchor.constraint(equalTo: pagingView.safeAreaLayoutGuide.bottomAnchor)
    }

    contentLayoutConstraints.tabTop?.isActive = position == .top
    contentLayoutConstraints.tabBottom?.isActive = position == .bottom
    contentLayoutConstraints.pageTop?.isActive = true
    contentLayoutConstraints.pageBottom?.isActive = true
  }

  private func applyPageHostOnlyLayout() {
    guard let pagingView, let pageHostView else { return }
    contentLayoutConstraints.pageTop?.isActive = false
    contentLayoutConstraints.pageBottom?.isActive = false
    contentLayoutConstraints.pageTop = pageHostView.topAnchor.constraint(equalTo: pagingView.safeAreaLayoutGuide.topAnchor)
    contentLayoutConstraints.pageBottom = pageHostView.bottomAnchor.constraint(equalTo: pagingView.bottomAnchor)
    contentLayoutConstraints.pageTop?.isActive = true
    contentLayoutConstraints.pageBottom?.isActive = true
  }

  private func applyNavigationBarPlacement(
    options: FKPagingNavigationBarTabOptions,
    tabBarHeightPolicy: FKPagingTabBarHeightPolicy
  ) {
    applyPageHostOnlyLayout()
    guard let host = resolveNavigationBarHost() else { return }

    if navigationTitleViewHost !== host {
      teardownNavigationBarTitleViewIfInstalled()
    }

    if options.suppressesHostTitle, savedHostTitle == nil {
      savedHostTitle = host.navigationItem.title
      host.navigationItem.title = nil
    }

    // UIKit sizes `titleView` via `sizeThatFits`; avoid explicit width/height constraints that
    // fight `_UINavigationBarTitleControl` and the back/trailing bar-button layout guides.
    tabBar.translatesAutoresizingMaskIntoConstraints = true

    applyNavigationBarContentInsets(options)

    let titleSlotWidth = navigationBarTitleSlotWidth(for: host, options: options)
    let barHeight = resolvedTabBarHeight(
      placement: .navigationBar(options),
      tabBarHeightPolicy: tabBarHeightPolicy
    )
    let fittingSize = tabBar.sizeThatFits(CGSize(width: titleSlotWidth, height: barHeight))
    tabBar.bounds = CGRect(origin: .zero, size: fittingSize)

    if host.navigationItem.titleView !== tabBar {
      previousTitleView = host.navigationItem.titleView
      host.navigationItem.titleView = tabBar
      navigationTitleViewHost = host
    }

    tabBar.setNeedsLayout()
    tabBar.layoutIfNeeded()
    host.navigationItem.titleView?.setNeedsLayout()
    host.navigationController?.navigationBar.setNeedsLayout()
  }

  private func navigationBarTitleSlotWidth(
    for host: UIViewController,
    options: FKPagingNavigationBarTabOptions
  ) -> CGFloat {
    let width = host.view.bounds.width
    let chromeAllowance: CGFloat = 96 + options.horizontalInset * 2
    guard width > 1 else { return max(120, 280 - chromeAllowance) }
    return max(120, width - chromeAllowance)
  }

  /// Applies ``FKPagingNavigationBarTabOptions/horizontalInset`` as tab-strip content padding.
  private func applyNavigationBarContentInsets(_ options: FKPagingNavigationBarTabOptions) {
    var config = tabBar.configuration
    var insets = config.layout.contentInsets
    insets.leading = options.horizontalInset
    insets.trailing = options.horizontalInset
    guard config.layout.contentInsets != insets else { return }
    config.layout.contentInsets = insets
    tabBar.applyConfiguration(config)
  }

  private func resolveNavigationBarHost() -> UIViewController? {
    if let tabBarNavigationHost { return tabBarNavigationHost }
    if let parent = pagingViewController?.parent, parent.navigationController != nil { return parent }
    if pagingViewController?.navigationController != nil { return pagingViewController }
    return nil
  }
}
