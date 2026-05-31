import UIKit
import FKUIKit

/// ``FKPagingEagerDataSource`` with ``reloadFromDataSource()``.
@MainActor
final class FKPagingDataSourceExampleViewController: UIViewController {
  private let pagingController: FKPagingController
  private let dataSource = FKPagingDemoEagerDataSource(initialCount: 3)

  init() {
    pagingController = FKPagingController(
      tabs: [],
      viewControllers: [],
      configuration: FKPagingConfiguration()
    )
    super.init(nibName: nil, bundle: nil)
    pagingController.dataSource = dataSource
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Data source"
    view.backgroundColor = .systemBackground
    pagingController.reloadFromDataSource()
    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)

    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Add page + reload") { [weak self] in
      guard let self else { return }
      dataSource.appendPage()
      pagingController.reloadFromDataSource()
    })
    stack.addArrangedSubview(FKTabBarExampleSupport.actionButton("Remove last page") { [weak self] in
      guard let self else { return }
      dataSource.removeLastPage()
      pagingController.reloadFromDataSource()
    })

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}

@MainActor
private final class FKPagingDemoEagerDataSource: FKPagingEagerDataSource {
  private var tabs: [FKTabBarItem]
  private var pages: [UIViewController]

  init(initialCount: Int) {
    tabs = FKTabBarExampleSupport.makeItems(initialCount)
    pages = (0..<initialCount).map { idx in
      FKPagingDemoPageViewController(color: .systemFill, titleText: "DS \(idx)")
    }
  }

  func appendPage() {
    let index = tabs.count
    let item = FKTabBarItem(
      id: "tab-\(index)",
      title: .init(normal: .init(text: "Page \(index)")),
      image: .init(normal: .init(source: .systemSymbol(name: "doc")))
    )
    tabs.append(item)
    pages.append(FKPagingDemoPageViewController(color: .systemTeal, titleText: "DS \(index)"))
  }

  func removeLastPage() {
    guard !tabs.isEmpty else { return }
    tabs.removeLast()
    pages.removeLast()
  }

  func numberOfPages(in pagingController: FKPagingController) -> Int {
    tabs.count
  }

  func pagingController(_ pagingController: FKPagingController, tabItemAt index: Int) -> FKTabBarItem {
    tabs[index]
  }

  func pagingController(_ pagingController: FKPagingController, viewControllerAt index: Int) -> UIViewController {
    pages[index]
  }
}
