import UIKit
import FKUIKit

/// Aligns page storage after runtime tab visibility changes via ``FKPagingController/syncPagesWithVisibleTabs(tabs:viewControllers:selectedIndex:)``.
@MainActor
final class FKPagingSyncVisibleTabsExampleViewController: UIViewController {
  private let pagingController: FKPagingController
  private var tabs: [FKTabBarItem]
  private var pages: [UIViewController]
  private var middleTabHidden = false

  init() {
    tabs = FKTabBarExampleSupport.makeItems(5)
    pages = (0..<5).map { idx in
      FKPagingDemoPageViewController(color: .systemFill, titleText: "Page \(idx)")
    }
    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      selectedIndex: 0,
      tabConfiguration: FKTabBarPresets.pagerHeader()
    )
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Sync visible tabs"
    view.backgroundColor = .systemBackground

    addChild(pagingController)
    pagingController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(pagingController.view)
    pagingController.didMove(toParent: self)

    let caption = UILabel()
    caption.numberOfLines = 0
    caption.font = .preferredFont(forTextStyle: .footnote)
    caption.textColor = .secondaryLabel
    caption.text =
      "Toggles isHidden on tab 2, then calls syncPagesWithVisibleTabs so pageCount matches visibleItems.count."
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let toggle = FKTabBarExampleSupport.actionButton("Toggle hide tab 2 + sync") { [weak self] in
      self?.toggleMiddleTabVisibility()
    }
    toggle.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(toggle)

    NSLayoutConstraint.activate([
      pagingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      pagingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pagingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pagingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      caption.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      caption.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      caption.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -52),

      toggle.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      toggle.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      toggle.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func toggleMiddleTabVisibility() {
    middleTabHidden.toggle()
    tabs[2].isHidden = middleTabHidden

    let visibleTabs = tabs.filter { !$0.isHidden }
    let visiblePages = pages.enumerated().compactMap { idx, page -> UIViewController? in
      tabs[idx].isHidden ? nil : page
    }

    pagingController.syncPagesWithVisibleTabs(
      tabs: tabs,
      viewControllers: visiblePages,
      selectedIndex: min(pagingController.selectedIndex, max(0, visibleTabs.count - 1))
    )
  }
}
