import UIKit
import FKUIKit

/// ``FKPagingTabBarPlacement/external`` — host lays out ``FKPagingController/tabBar`` above the page host.
@MainActor
final class FKPagingExternalTabBarPlacementExampleViewController: UIViewController {
  private let pagingController: FKPagingController

  init() {
    var config = FKPagingConfiguration()
    config.tabBarPlacement = .external
    config.tabBarHeightPolicy = .fixed(48)

    var tabs = FKTabBarExampleSupport.makeItems(4)
    tabs[1].badge.state.normal = .dot
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemBlue, titleText: "External A"),
      FKPagingDemoPageViewController(color: .systemGreen, titleText: "External B"),
      FKPagingDemoListViewController(headerTitle: "External C"),
      FKPagingDemoPageViewController(color: .systemPurple, titleText: "External D"),
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
    title = "External tab strip"
    view.backgroundColor = .systemBackground

    let chromeLabel = UILabel()
    chromeLabel.translatesAutoresizingMaskIntoConstraints = false
    chromeLabel.font = .preferredFont(forTextStyle: .caption1)
    chromeLabel.textColor = .secondaryLabel
    chromeLabel.textAlignment = .center
    chromeLabel.text = "Custom host chrome — pager does not layout the tab strip"

    let footnote = UILabel()
    footnote.translatesAutoresizingMaskIntoConstraints = false
    footnote.font = .preferredFont(forTextStyle: .footnote)
    footnote.textColor = .secondaryLabel
    footnote.numberOfLines = 0
    footnote.textAlignment = .center
    footnote.text =
      "isTabBarExternallyManaged = \(pagingController.isTabBarExternallyManaged). "
      + "Use for toolbars, composite headers, or split-view chrome where the host owns tab layout."

    addChild(pagingController)
    pagingController.view.translatesAutoresizingMaskIntoConstraints = false
    pagingController.view.clipsToBounds = true
    view.addSubview(pagingController.view)

    let tabBar = pagingController.tabBar
    tabBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(tabBar)

    view.addSubview(chromeLabel)
    view.addSubview(footnote)

    NSLayoutConstraint.activate([
      chromeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 4),
      chromeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
      chromeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

      tabBar.topAnchor.constraint(equalTo: chromeLabel.bottomAnchor, constant: 4),
      tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tabBar.heightAnchor.constraint(equalToConstant: 48),

      pagingController.view.topAnchor.constraint(equalTo: tabBar.bottomAnchor),
      pagingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pagingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pagingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      footnote.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
      footnote.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
      footnote.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    pagingController.didMove(toParent: self)
  }
}
