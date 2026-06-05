import FKCoreKit
import FKUIKit
import UIKit

/// ``FKPagingEmptyStateConfiguration`` when ``pageCount`` is zero.
@MainActor
final class FKPagingEmptyStateExampleViewController: UIViewController {
  private let pagingController: FKPagingController
  private var languageObservation: FKI18nObservationToken?

  init() {
    var config = FKPagingConfiguration()
    config.emptyStateConfiguration = FKPagingEmptyStateConfiguration(isEnabled: true)
    pagingController = FKPagingController(
      tabs: [],
      viewControllers: [],
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
    title = "Empty state"
    view.backgroundColor = .systemBackground
    FKPagingDemoSupport.embedFullScreen(pagingController, in: self)
    languageObservation = FKI18nManager.shared.observeLanguageChange { [weak self] _ in
      Task { @MainActor in self?.refreshEmptyStateMessage() }
    }
    refreshEmptyStateMessage()

    let addButton = FKTabBarExampleSupport.actionButton("Add 3 pages") { [weak self] in
      guard let self else { return }
      let tabs = FKTabBarExampleSupport.makeItems(3)
      let pages: [UIViewController] = [
        FKPagingDemoPageViewController(color: .systemBlue, titleText: "First"),
        FKPagingDemoPageViewController(color: .systemGreen, titleText: "Second"),
        FKPagingDemoPageViewController(color: .systemOrange, titleText: "Third"),
      ]
      pagingController.setContent(tabs: tabs, viewControllers: pages, selectedIndex: 0)
    }
    addButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(addButton)

    NSLayoutConstraint.activate([
      addButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      addButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])
  }

  private func refreshEmptyStateMessage() {
    var config = pagingController.configuration
    config.emptyStateConfiguration.message = FKUIKitI18n.string("fkuikit.paging.no_pages")
    pagingController.configuration = config
  }
}
