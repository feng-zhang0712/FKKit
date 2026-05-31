import UIKit
import FKUIKit

/// Incremental tab/page updates via ``FKPagingController/applyContentChanges(_:)`` (lazy mode).
@MainActor
final class FKPagingIncrementalChangesExampleViewController: UIViewController {
  private let pagingController: FKPagingController
  private var tabs: [FKTabBarItem]

  init() {
    tabs = FKTabBarExampleSupport.makeItems(4)
    pagingController = FKPagingController(
      tabs: tabs,
      pageCount: 4,
      pageProvider: { index in
        let colors: [UIColor] = [.systemBlue, .systemGreen, .systemOrange, .systemPurple]
        if index == 2 {
          return FKPagingDemoListViewController(headerTitle: "C list")
        }
        return FKPagingDemoPageViewController(color: colors[index % colors.count], titleText: "Page \(index)")
      },
      selectedIndex: 1,
      configuration: FKPagingConfiguration(
        preloadRange: 1,
        retentionPolicy: .keepNear(distance: 1)
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
    title = "applyContentChanges"
    view.backgroundColor = .systemBackground
    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Hide tab @1") { [weak self] in
      self?.hideSecondTab()
    })
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Invalidate current page") { [weak self] in
      guard let self else { return }
      pagingController.applyContentChanges([.invalidatePage(at: pagingController.selectedIndex)])
    })

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func hideSecondTab() {
    guard tabs.count > 1 else { return }
    tabs[1].isHidden = true
    pagingController.applyContentChanges([
      .tab(FKTabBarItemChange(kind: .update(tabs[1], atVisibleIndex: 1))),
    ])
  }
}
