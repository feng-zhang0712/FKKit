import UIKit
import FKUIKit

/// Demonstrates standard eager paging, programmatic navigation, and stress scheduling.
@MainActor
final class FKPagingBasicsExampleViewController: UIViewController {
  private let pagingController: FKPagingController
  private var stressWorkItem: DispatchWorkItem?

  init() {
    var tabs = FKTabBarExampleSupport.makeItems(5)
    tabs[2].badge.state.normal = .count(6)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemBlue, titleText: "Home"),
      FKPagingDemoPageViewController(color: .systemGreen, titleText: "Explore"),
      FKPagingDemoListViewController(headerTitle: "Inbox"),
      FKPagingDemoPageViewController(color: .systemOrange, titleText: "Profile"),
      FKPagingDemoPageViewController(color: .systemPurple, titleText: "Settings"),
    ]
    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      selectedIndex: 0,
      tabConfiguration: FKTabBarPresets.pagerHeader(),
      configuration: FKPagingConfiguration(
        tabBarHeightPolicy: .fixed(52),
        allowsSwipePaging: true,
        preloadRange: 1,
        retentionPolicy: .keepNear(distance: 1),
        gesturePolicy: .preferNavigationBackGesture(edgeWidth: 28)
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
    title = "Basics"
    view.backgroundColor = .systemBackground
    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)

    let note = UILabel()
    note.font = .preferredFont(forTextStyle: .footnote)
    note.textColor = .secondaryLabel
    note.numberOfLines = 0
    note.text =
      "Stress x20 fires 20 rapid programmatic page changes (no animation) to validate the transition queue. For animated paging, use Prev/Next. Swipe works on the pager; Inbox is a nested UITableView."
    note.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(note)

    installToolbarActions()

    NSLayoutConstraint.activate([
      note.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      note.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      note.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -62),
    ])
  }

  private func installToolbarActions() {
    let panel = UIStackView()
    panel.axis = .horizontal
    panel.spacing = 8
    panel.distribution = .fillEqually
    panel.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(panel)

    panel.addArrangedSubview(FKTabBarExampleSupport.actionButton("Prev") { [weak self] in
      guard let self else { return }
      pagingController.setSelectedIndex(max(0, pagingController.selectedIndex - 1), animated: true)
    })
    panel.addArrangedSubview(FKTabBarExampleSupport.actionButton("Next") { [weak self] in
      guard let self else { return }
      pagingController.setSelectedIndex(min(pagingController.pageCount - 1, pagingController.selectedIndex + 1), animated: true)
    })
    panel.addArrangedSubview(FKTabBarExampleSupport.actionButton("Stress x20") { [weak self] in
      guard let self else { return }
      stressWorkItem?.cancel()
      let work = DispatchWorkItem { [weak self] in
        guard let self else { return }
        for step in 0..<20 {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.04 * Double(step)) { [weak self] in
            guard let self else { return }
            let target = (step * 3) % max(1, self.pagingController.pageCount)
            self.pagingController.setSelectedIndex(target, animated: false)
          }
        }
      }
      stressWorkItem = work
      DispatchQueue.main.async(execute: work)
    })

    NSLayoutConstraint.activate([
      panel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      panel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      panel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }
}
