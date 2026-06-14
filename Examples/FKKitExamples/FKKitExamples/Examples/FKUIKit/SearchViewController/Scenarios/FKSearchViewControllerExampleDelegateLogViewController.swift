import FKUIKit
import UIKit

/// ``FKSearchViewControllerDelegate`` when callbacks are unset.
final class FKSearchViewControllerExampleDelegateLogViewController: UIViewController, FKSearchViewControllerDelegate {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()
  private let logView = FKSearchViewControllerExampleSupport.makeEventLogTextView()
  private lazy var searchViewController: FKSearchViewController = {
    let vc = FKSearchViewController(
      configuration: FKSearchViewControllerDefaults.localFilter(placement: .stickyHeader),
      placeholder: "Tap rows to log"
    )
    vc.localFilterProvider = provider
    return vc
  }()

  init() {
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Delegate · Selection Log"
    view.backgroundColor = .systemGroupedBackground
    searchViewController.delegate = self

    logView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(logView)

    FKSearchViewControllerExampleSupport.embed(
      searchViewController,
      in: self,
      below: view.safeAreaLayoutGuide.topAnchor,
      bottomAnchor: logView.topAnchor
    )

    NSLayoutConstraint.activate([
      logView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
      logView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
      logView.heightAnchor.constraint(equalToConstant: 140),
    ])

    FKSearchViewControllerExampleSupport.appendLog(logView, "Delegate receives events when matching callbacks are nil")
  }

  func searchViewController(_ viewController: FKSearchViewController, stateChanged state: FKSearchPresentationState) {
    FKSearchViewControllerExampleSupport.appendLog(
      logView,
      "delegate state → \(FKSearchViewControllerExampleSupport.formatPresentationState(state))"
    )
  }

  func searchViewController(_ viewController: FKSearchViewController, didSelect item: FKListItemID) {
    FKSearchViewControllerExampleSupport.appendLog(logView, "delegate selected → \(item.rawValue)")
  }
}
