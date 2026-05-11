import UIKit
import FKUIKit

/// Runtime `setContent` reload for tab/model changes without reconstructing the shell controller.
@MainActor
final class FKPagingDynamicContentExampleViewController: UIViewController {
  private let pagingController: FKPagingController
  private var useExtendedTabs = false

  init() {
    let tabs = FKTabBarExampleSupport.makeItems(3)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemBlue, titleText: "Short set — A"),
      FKPagingDemoPageViewController(color: .systemGreen, titleText: "Short set — B"),
      FKPagingDemoPageViewController(color: .systemOrange, titleText: "Short set — C"),
    ]
    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      selectedIndex: 1,
      configuration: FKPagingConfiguration(preloadRange: 1)
    )
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Dynamic content"
    view.backgroundColor = .systemBackground

    addChild(pagingController)
    pagingController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(pagingController.view)
    pagingController.didMove(toParent: self)

    let caption = UILabel()
    caption.numberOfLines = 0
    caption.font = .preferredFont(forTextStyle: .footnote)
    caption.textColor = .secondaryLabel
    caption.text = "Reload preserves selection when possible via FKTabBar update policies."
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    let toggle = FKTabBarExampleSupport.actionButton("Toggle 3 ↔ 8 tabs") { [weak self] in
      self?.reloadContent()
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

  private func reloadContent() {
    useExtendedTabs.toggle()
    if useExtendedTabs {
      let tabs = FKTabBarExampleSupport.makeItems(8)
      let pages: [UIViewController] = (0..<8).map { idx in
        FKPagingDemoPageViewController(
          color: .secondarySystemFill,
          titleText: "Extended \(idx)"
        )
      }
      pagingController.setContent(tabs: tabs, viewControllers: pages, selectedIndex: 3)
    } else {
      let tabs = FKTabBarExampleSupport.makeItems(3)
      let pages: [UIViewController] = [
        FKPagingDemoPageViewController(color: .systemBlue, titleText: "Short — A"),
        FKPagingDemoPageViewController(color: .systemGreen, titleText: "Short — B"),
        FKPagingDemoPageViewController(color: .systemOrange, titleText: "Short — C"),
      ]
      pagingController.setContent(tabs: tabs, viewControllers: pages, selectedIndex: 1)
    }
  }
}
