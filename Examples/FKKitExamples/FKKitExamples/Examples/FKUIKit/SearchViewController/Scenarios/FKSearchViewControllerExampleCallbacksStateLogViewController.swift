import FKUIKit
import UIKit

/// ``FKSearchViewControllerCallbacks`` — logs ``FKSearchPresentationState`` transitions and ``setQuery(_:)``.
final class FKSearchViewControllerExampleCallbacksStateLogViewController: UIViewController {
  private let provider = FKSearchViewControllerExampleSupport.FruitLocalFilterProvider()
  private let logView = FKSearchViewControllerExampleSupport.makeEventLogTextView()
  private lazy var searchViewController: FKSearchViewController = {
    let vc = FKSearchViewController(
      configuration: FKSearchViewControllerDefaults.localFilter(placement: .stickyHeader),
      placeholder: "Type to log states"
    )
    vc.localFilterProvider = provider
    vc.callbacks.onPresentationStateChanged = { [weak self] state in
      guard let self else { return }
      FKSearchViewControllerExampleSupport.appendLog(
        self.logView,
        "state → \(FKSearchViewControllerExampleSupport.formatPresentationState(state))"
      )
    }
    vc.callbacks.onResultSelected = { [weak self] itemID in
      guard let self else { return }
      FKSearchViewControllerExampleSupport.appendLog(self.logView, "selected → \(itemID.rawValue)")
    }
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
    title = "Callbacks · State Log"
    view.backgroundColor = .systemGroupedBackground

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

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      title: "Set \"Apple\"",
      style: .plain,
      target: self,
      action: #selector(setAppleQuery)
    )

    FKSearchViewControllerExampleSupport.appendLog(logView, "Ready — callbacks take precedence over delegate")
  }

  @objc private func setAppleQuery() {
    searchViewController.setQuery("Apple", options: .withSearchQuery)
    FKSearchViewControllerExampleSupport.appendLog(logView, "setQuery(\"Apple\")")
  }
}
