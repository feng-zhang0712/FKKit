import UIKit
import FKUIKit

/// ``FKPagingTabBarPlacement/contentTop`` (default) — tab strip inside the paging view below the safe-area top.
@MainActor
final class FKPagingContentTopPlacementExampleViewController: UIViewController {
  private let pagingController: FKPagingController

  init() {
    var config = FKPagingConfiguration()
    config.tabBarPlacement = .contentTop
    config.tabBarHeightPolicy = .fixed(52)

    let tabs = FKTabBarExampleSupport.makeItems(4)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemBlue, titleText: "Content top A"),
      FKPagingDemoPageViewController(color: .systemGreen, titleText: "Content top B"),
      FKPagingDemoListViewController(headerTitle: "Content top C"),
      FKPagingDemoPageViewController(color: .systemOrange, titleText: "Content top D"),
    ]

    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      tabConfiguration: FKTabBarPresets.pagerHeader(),
      configuration: config
    )
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Content area (top)"
    view.backgroundColor = .systemBackground
    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)

    let note = UILabel()
    note.translatesAutoresizingMaskIntoConstraints = false
    note.font = .preferredFont(forTextStyle: .footnote)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.textAlignment = .center
    note.text =
      "Default placement: tabBarPlacement = .contentTop. "
      + "The strip sits below the navigation bar (when pushed in a stack) inside the paging controller’s view."
    view.addSubview(note)
    NSLayoutConstraint.activate([
      note.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
      note.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
      note.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}
