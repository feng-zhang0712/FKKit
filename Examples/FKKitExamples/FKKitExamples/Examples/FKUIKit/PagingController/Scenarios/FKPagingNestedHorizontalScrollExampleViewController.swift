import UIKit
import FKUIKit

/// ``FKPagingNestedHorizontalScrollPolicy/preferNestedHorizontalScroll`` with in-page carousel.
@MainActor
final class FKPagingNestedHorizontalScrollExampleViewController: UIViewController {
  private let pagingController: FKPagingController

  init() {
    var config = FKPagingConfiguration()
    config.nestedHorizontalScrollPolicy = .preferNestedHorizontalScroll
    let tabs = FKTabBarExampleSupport.makeItems(3)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemGray5, titleText: "Plain page"),
      FKPagingDemoHorizontalCarouselViewController(headerTitle: "Swipe carousel horizontally"),
      FKPagingDemoListViewController(headerTitle: "Vertical list"),
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
    title = "Nested horizontal scroll"
    view.backgroundColor = .systemBackground
    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)

    let caption = UILabel()
    caption.font = .preferredFont(forTextStyle: .footnote)
    caption.textColor = .secondaryLabel
    caption.numberOfLines = 0
    caption.text = "Middle tab hosts a horizontal UICollectionView. preferNestedHorizontalScroll installs require(toFail:) on nested pans in the settled page."
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    NSLayoutConstraint.activate([
      caption.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      caption.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      caption.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}
