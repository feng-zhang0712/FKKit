import UIKit
import FKUIKit

/// Bottom-docked tab strip and configurable ``FKPagingConfiguration/interPageSpacing``.
@MainActor
final class FKPagingLayoutSpacingExampleViewController: UIViewController {
  private let pagingController: FKPagingController
  private var spacingBarButton: UIBarButtonItem?
  private let hintLabel = UILabel()

  init() {
    var config = FKPagingConfiguration()
    config.tabBarPlacement = .contentBottom
    config.interPageSpacing = 16
    let tabs = FKTabBarExampleSupport.makeItems(4)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemTeal, titleText: "Bottom tabs"),
      FKPagingDemoPageViewController(color: .systemPurple, titleText: "Explore"),
      FKPagingDemoListViewController(headerTitle: "Scrollable page"),
      FKPagingDemoPageViewController(color: .systemOrange, titleText: "Swipe peek"),
    ]
    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      tabConfiguration: FKTabBarPresets.bottomDocked(),
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
    title = "Layout & spacing"
    view.backgroundColor = .systemBackground
    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)
    installSpacingMenu()
    installHintLabel()
  }

  private func installHintLabel() {
    hintLabel.translatesAutoresizingMaskIntoConstraints = false
    hintLabel.font = .preferredFont(forTextStyle: .footnote)
    hintLabel.textColor = .secondaryLabel
    hintLabel.textAlignment = .center
    hintLabel.numberOfLines = 0
    hintLabel.text =
      "Bottom tab strip is always visible. interPageSpacing shows only while swiping — drag slowly between tabs and compare 0 pt vs 24 pt in the menu."
    view.addSubview(hintLabel)
    NSLayoutConstraint.activate([
      hintLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
      hintLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
      hintLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -72),
    ])
  }

  private func installSpacingMenu() {
    let button = UIBarButtonItem(title: "16pt", menu: makeSpacingMenu(selectedSpacing: 16))
    spacingBarButton = button
    navigationItem.rightBarButtonItem = button
  }

  private func makeSpacingMenu(selectedSpacing: CGFloat) -> UIMenu {
    let values: [CGFloat] = [0, 8, 16, 24]
    let actions = values.map { spacing in
      UIAction(
        title: "\(Int(spacing)) pt",
        state: spacing == selectedSpacing ? .on : .off
      ) { [weak self] _ in
        self?.applySpacing(spacing)
      }
    }
    return UIMenu(title: "interPageSpacing", children: actions)
  }

  private func applySpacing(_ spacing: CGFloat) {
    pagingController.configuration.interPageSpacing = spacing
    spacingBarButton?.title = spacing == 0 ? "0pt" : "\(Int(spacing))pt"
    spacingBarButton?.menu = makeSpacingMenu(selectedSpacing: spacing)
  }
}
