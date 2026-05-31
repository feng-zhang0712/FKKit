import UIKit
import FKUIKit

/// Directional swipe control with ``allowsSwipePagingTo`` (block forward from middle tab).
@MainActor
final class FKPagingSwipeDirectionExampleViewController: UIViewController {
  private let pagingController: FKPagingController

  init() {
    var config = FKPagingConfiguration()
    config.allowsSwipePagingTo = { index, direction in
      if index == 2, direction == .forward { return false }
      return true
    }
    let tabs = FKTabBarExampleSupport.makeItems(5)
    let pages: [UIViewController] = (0..<5).map { idx in
      FKPagingDemoPageViewController(color: .systemFill, titleText: "Page \(idx)")
    }
    pagingController = FKPagingController(tabs: tabs, viewControllers: pages, selectedIndex: 2, configuration: config)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Directional swipe"
    view.backgroundColor = .systemBackground
    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)

    let caption = UILabel()
    caption.font = .preferredFont(forTextStyle: .footnote)
    caption.textColor = .secondaryLabel
    caption.numberOfLines = 0
    caption.text = "Starts on page 2. Forward swipe is blocked; reverse swipe still works."
    caption.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(caption)

    NSLayoutConstraint.activate([
      caption.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      caption.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      caption.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}
