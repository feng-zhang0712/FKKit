import UIKit
import FKUIKit

/// Demonstrates ``FKPagingConfiguration/pageSwitchGate`` `.controlled` with ``FKPagingController/commitPageSwitch(to:animated:)``.
@MainActor
final class FKPagingControlledGateExampleViewController: UIViewController, FKPagingControllerDelegate {
  private let pagingController: FKPagingController
  private let logView = UITextView()
  private var commitWorkItem: DispatchWorkItem?

  init() {
    let tabs = FKTabBarExampleSupport.makeItems(4)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemBlue, titleText: "Await gate"),
      FKPagingDemoPageViewController(color: .systemGreen, titleText: "Pending"),
      FKPagingDemoListViewController(headerTitle: "Commit me"),
      FKPagingDemoPageViewController(color: .systemOrange, titleText: "Settled"),
    ]
    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      tabConfiguration: FKTabBarPresets.pagerHeader(),
      configuration: FKPagingConfiguration(
        tabBarHeightPolicy: .automatic,
        allowsSwipePaging: true,
        pageSwitchGate: .controlled
      )
    )
    super.init(nibName: nil, bundle: nil)
    pagingController.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Controlled gate"
    view.backgroundColor = .systemGroupedBackground

    addChild(pagingController)
    pagingController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(pagingController.view)
    pagingController.didMove(toParent: self)

    logView.translatesAutoresizingMaskIntoConstraints = false
    logView.isEditable = false
    logView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemGroupedBackground
    logView.layer.cornerRadius = 8
    logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    view.addSubview(logView)

    let commitButton = FKTabBarExampleSupport.actionButton("Commit pending (simulated 400ms)") { [weak self] in
      self?.commitPendingAfterDelay()
    }
    commitButton.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(commitButton)

    NSLayoutConstraint.activate([
      pagingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      pagingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pagingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pagingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.55),

      commitButton.topAnchor.constraint(equalTo: pagingController.view.bottomAnchor, constant: 8),
      commitButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      commitButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),

      logView.topAnchor.constraint(equalTo: commitButton.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      logView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    appendLog("Tab taps set pendingPageIndex. Swipe paging still works immediately.")
  }

  private func commitPendingAfterDelay() {
    guard let pending = pagingController.pendingPageIndex else {
      appendLog("No pendingPageIndex — tap a different tab first.")
      return
    }
    commitWorkItem?.cancel()
    appendLog("Validating switch to @\(pending)…")
    let work = DispatchWorkItem { [weak self] in
      guard let self else { return }
      self.pagingController.commitPageSwitch(to: pending, animated: true)
      self.appendLog("commitPageSwitch(to: \(pending))")
    }
    commitWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
  }

  private func appendLog(_ line: String) {
    logView.text = (logView.text ?? "") + line + "\n"
    let bottom = NSRange(location: logView.text.count - 1, length: 1)
    logView.scrollRangeToVisible(bottom)
  }

  func pagingController(_ controller: FKPagingController, didSettleAt index: Int) {
    appendLog("settled @ \(index)")
  }
}
