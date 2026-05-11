import UIKit
import FKUIKit

/// Demonstrates wiring `FKPagingController` with different `FKTabBar` indicator styles.
///
/// Highlights:
/// - Pass a baseline ``FKTabBarAppearance`` into ``FKPagingController/init(tabs:viewControllers:selectedIndex:tabAppearance:tabLayoutOptions:tabAnimationOptions:configuration:)``.
/// - For interactive paging, prefer ``FKTabBarLineIndicatorConfiguration/followMode`` ``FKTabBarIndicatorFollowMode/trackContentProgress`` on line indicators.
/// - Mutate ``FKTabBar/configuration`` (or appearance subfields) to swap styles at runtime.
/// - Custom indicators use ``FKTabBar/indicatorViewProvider``; ``FKTabBarAppearance/indicatorZOrder`` controls whether the custom view sits below or above tab content.
@MainActor
final class FKPagingTabBarIndicatorExampleViewController: UIViewController {
  private enum IndicatorDemo: String, CaseIterable {
    case none
    case lineProgress
    case background
    case gradient
    case pill
    case customBehind
    case customOverlay
  }

  private let pagingController: FKPagingController
  private var selectedDemo: IndicatorDemo = .lineProgress

  init() {
    let tabs = FKTabBarExampleSupport.makeItems(4)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemBlue, titleText: "Home"),
      FKPagingDemoPageViewController(color: .systemGreen, titleText: "Explore"),
      FKPagingDemoListViewController(headerTitle: "Inbox"),
      FKPagingDemoPageViewController(color: .systemOrange, titleText: "Profile"),
    ]
    let tabAppearance = Self.makeAppearance(for: .lineProgress)
    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      selectedIndex: 0,
      tabAppearance: tabAppearance,
      configuration: FKPagingConfiguration(
        tabBarHeight: 52,
        allowsSwipePaging: true,
        preloadRange: 1,
        retentionPolicy: .keepNear(distance: 1),
        gesturePolicy: .preferNavigationBackGesture(edgeWidth: 28)
      )
    )
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Tab indicators"
    view.backgroundColor = .systemBackground

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Style",
      menu: makeIndicatorMenu()
    )

    pagingController.tabBar.indicatorViewProvider = { id in
      guard id == "paging.demo.custom" else { return nil }
      let view = UIView()
      view.backgroundColor = .systemOrange.withAlphaComponent(0.4)
      view.layer.cornerRadius = 10
      return view
    }

    embedFullScreen(pagingController)

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .footnote)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text =
      "Open the Style menu to swap indicators. Non-line styles use followMode .trackContentProgress so highlights track swipe like the line. Custom (behind) uses indicatorZOrder .automatic; Custom (overlay) uses .aboveTabItems."
    note.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(note)

    let panel = UIStackView()
    panel.axis = .horizontal
    panel.spacing = 8
    panel.distribution = .fillEqually
    panel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(panel)
    panel.addArrangedSubview(FKTabBarExampleSupport.actionButton("Prev") { [weak self] in
      guard let self else { return }
      self.pagingController.setSelectedIndex(max(0, self.pagingController.selectedIndex - 1), animated: true)
    })
    panel.addArrangedSubview(FKTabBarExampleSupport.actionButton("Next") { [weak self] in
      guard let self else { return }
      self.pagingController.setSelectedIndex(
        min(self.pagingController.pageCount - 1, self.pagingController.selectedIndex + 1),
        animated: true
      )
    })

    NSLayoutConstraint.activate([
      note.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      note.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      note.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -62),

      panel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      panel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      panel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func embedFullScreen(_ child: UIViewController) {
    addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    child.view.clipsToBounds = true
    view.addSubview(child.view)
    NSLayoutConstraint.activate([
      child.view.topAnchor.constraint(equalTo: view.topAnchor),
      child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    child.didMove(toParent: self)
  }

  private func makeIndicatorMenu() -> UIMenu {
    UIMenu(
      title: "Indicator",
      children: IndicatorDemo.allCases.map { kind in
        UIAction(
          title: Self.menuTitle(for: kind),
          state: kind == selectedDemo ? .on : .off
        ) { [weak self] _ in
          self?.applyDemo(kind)
        }
      }
    )
  }

  private static func menuTitle(for kind: IndicatorDemo) -> String {
    switch kind {
    case .none: return "None"
    case .lineProgress: return "Line · trackContentProgress"
    case .background: return "Background"
    case .gradient: return "Gradient"
    case .pill: return "Pill"
    case .customBehind: return "Custom · behind items"
    case .customOverlay: return "Custom · overlay (above items)"
    }
  }

  private func applyDemo(_ kind: IndicatorDemo) {
    selectedDemo = kind
    var cfg = pagingController.tabBar.configuration
    cfg.appearance = Self.makeAppearance(for: kind)
    pagingController.tabBar.configuration = cfg
    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Style",
      menu: makeIndicatorMenu()
    )
  }

  private static func makeAppearance(for kind: IndicatorDemo) -> FKTabBarAppearance {
    let insets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
    switch kind {
    case .none:
      return FKTabBarAppearance(indicatorStyle: .none)
    case .lineProgress:
      return FKTabBarAppearance(
        indicatorStyle: .line(
          FKTabBarLineIndicatorConfiguration(
            position: .bottom,
            thickness: 3,
            fill: .solid(.systemBlue),
            leadingInset: 10,
            trailingInset: 10,
            followMode: .trackContentProgress
          )
        )
      )
    case .background:
      return FKTabBarAppearance(
        indicatorStyle: FKTabBarIndicatorStyle.background(
          FKTabBarBackgroundIndicatorConfiguration(
            insets: insets,
            cornerRadius: 10,
            fill: .solid(.tertiarySystemFill),
            followMode: .trackContentProgress
          )
        )
      )
    case .gradient:
      return FKTabBarAppearance(
        indicatorStyle: FKTabBarIndicatorStyle.gradient(
          FKTabBarBackgroundIndicatorConfiguration(
            insets: insets,
            cornerRadius: 10,
            fill: .gradient(
              colors: [.systemPink, .systemPurple],
              startPoint: .init(x: 0, y: 0.5),
              endPoint: .init(x: 1, y: 0.5)
            ),
            shadowColor: .black,
            shadowOpacity: 0.12,
            shadowRadius: 4,
            shadowOffset: .init(width: 0, height: 2),
            followMode: .trackContentProgress
          )
        )
      )
    case .pill:
      return FKTabBarAppearance(
        indicatorStyle: FKTabBarIndicatorStyle.pill(
          FKTabBarBackgroundIndicatorConfiguration(
            insets: insets,
            cornerRadius: 999,
            fill: .solid(.secondarySystemFill),
            followMode: .trackContentProgress
          )
        )
      )
    case .customBehind:
      return FKTabBarAppearance(
        indicatorStyle: FKTabBarIndicatorStyle.custom(id: "paging.demo.custom", followMode: .trackContentProgress),
        indicatorZOrder: .automatic
      )
    case .customOverlay:
      return FKTabBarAppearance(
        indicatorStyle: FKTabBarIndicatorStyle.custom(id: "paging.demo.custom", followMode: .trackContentProgress),
        indicatorZOrder: .aboveTabItems
      )
    }
  }
}
