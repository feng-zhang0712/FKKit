import UIKit
import FKUIKit

/// Stable ID selection via ``setSelectedIndex(forItemID:animated:)`` after tab mutations.
@MainActor
final class FKPagingIDSelectionExampleViewController: UIViewController {
  private let pagingController: FKPagingController
  private var tabs: [FKTabBarItem]
  private var pages: [UIViewController]

  init() {
    tabs = FKTabBarExampleSupport.makeItems(5)
    pages = (0..<5).map { idx in
      FKPagingDemoPageViewController(color: .systemFill, titleText: "ID tab-\(idx)")
    }
    pagingController = FKPagingController(tabs: tabs, viewControllers: pages, selectedIndex: 0)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "ID selection"
    view.backgroundColor = .systemBackground
    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)

    let label = UILabel()
    label.font = .preferredFont(forTextStyle: .footnote)
    label.textColor = .secondaryLabel
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Select tab-3 by ID") { [weak self] in
      guard let self else { return }
      let ok = pagingController.setSelectedIndex(forItemID: "tab-3", animated: true)
      refreshLabel(label, extra: ok ? "selected tab-3" : "tab-3 not found")
    })
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Move tab-3 → index 0") { [weak self] in
      guard let self else { return }
      moveTabThreeToFront()
      refreshLabel(label, extra: "moved tab-3; ID selection still works")
    })

    refreshLabel(label, extra: "selectedItemID mirrors tabBar")

    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      label.bottomAnchor.constraint(equalTo: stack.topAnchor, constant: -8),

      stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func refreshLabel(_ label: UILabel, extra: String) {
    label.text = "\(extra)\nselectedItemID = \(pagingController.selectedItemID ?? "nil") @ index \(pagingController.selectedIndex)"
  }

  private func moveTabThreeToFront() {
    guard let source = tabs.firstIndex(where: { $0.id == "tab-3" }) else { return }
    let tab = tabs.remove(at: source)
    let page = pages.remove(at: source)
    tabs.insert(tab, at: 0)
    pages.insert(page, at: 0)
    pagingController.setContent(tabs: tabs, viewControllers: pages, selectedIndex: pagingController.selectedIndex)
  }
}
