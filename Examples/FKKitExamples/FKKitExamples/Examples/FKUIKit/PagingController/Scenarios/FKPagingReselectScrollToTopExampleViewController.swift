import UIKit
import FKUIKit

/// ``FKPagingReselectBehavior/scrollPageToTop`` when re-tapping the active tab.
@MainActor
final class FKPagingReselectScrollToTopExampleViewController: UIViewController {
  private let pagingController: FKPagingController

  init() {
    var config = FKPagingConfiguration()
    config.reselectBehavior = .scrollPageToTop
    let tabs = FKTabBarExampleSupport.makeItems(3)
    let pages: [UIViewController] = [
      FKPagingDemoListViewController(headerTitle: "Reselect me"),
      FKPagingDemoPageViewController(color: .systemGreen, titleText: "Plain"),
      FKPagingDemoListViewController(headerTitle: "Also scrollable"),
    ]
    pagingController = FKPagingController(tabs: tabs, viewControllers: pages, configuration: config)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Reselect scroll to top"
    view.backgroundColor = .systemBackground
    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)

    let caption = UILabel()
    caption.font = .preferredFont(forTextStyle: .footnote)
    caption.textColor = .secondaryLabel
    caption.numberOfLines = 0
    caption.text = "Scroll a list page, then tap its tab again to scroll to top."
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    NSLayoutConstraint.activate([
      caption.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      caption.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      caption.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}
