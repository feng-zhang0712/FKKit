import UIKit
import FKUIKit

/// Controlled gate with configurable ``FKPagingPageSwitchGateScope``, ``shouldSwitchTo``, and pending commit/cancel.
@MainActor
final class FKPagingGateExampleViewController: UIViewController, FKPagingControllerDelegate {
  private let pagingController: FKPagingController
  private let logView = FKPagingDemoSupport.makeLogTextView()
  private var blockSwitches = false

  init() {
    let tabs = FKTabBarExampleSupport.makeItems(4)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemBlue, titleText: "Gate"),
      FKPagingDemoPageViewController(color: .systemGreen, titleText: "Pending"),
      FKPagingDemoListViewController(headerTitle: "Try swiping"),
      FKPagingDemoPageViewController(color: .systemOrange, titleText: "Commit"),
    ]
    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      configuration: FKPagingConfiguration(
        pageSwitchGate: .controlled,
        pageSwitchGateScope: .tabSelectionOnly
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
    view.addSubview(logView)

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false

    let scopeControl = UISegmentedControl(items: ["Tab", "Swipe", "All"])
    scopeControl.selectedSegmentIndex = 0
    scopeControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      switch control.selectedSegmentIndex {
      case 1: pagingController.configuration.pageSwitchGateScope = .swipePagingOnly
      case 2: pagingController.configuration.pageSwitchGateScope = .all
      default: pagingController.configuration.pageSwitchGateScope = .tabSelectionOnly
      }
      FKPagingDemoSupport.appendLog("scope = \(scopeLabel(for: control.selectedSegmentIndex))", to: logView)
    }, for: .valueChanged)
    stack.addArrangedSubview(labeledRow(title: "Gate scope", control: scopeControl))

    let vetoSwitch = UISwitch()
    vetoSwitch.addAction(UIAction { [weak self] action in
      guard let self, let toggle = action.sender as? UISwitch else { return }
      blockSwitches = toggle.isOn
      FKPagingDemoSupport.appendLog("shouldSwitchTo veto = \(toggle.isOn)", to: logView)
    }, for: .valueChanged)
    stack.addArrangedSubview(labeledRow(title: "Veto switches", control: vetoSwitch))

    let buttonRow = UIStackView()
    buttonRow.axis = .horizontal
    buttonRow.spacing = 8
    buttonRow.distribution = .fillEqually
    buttonRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("Commit pending") { [weak self] in
      guard let self, let pending = pagingController.pendingPageIndex else { return }
      pagingController.commitPageSwitch(to: pending, animated: true)
    })
    buttonRow.addArrangedSubview(FKTabBarExampleSupport.actionButton("Cancel pending") { [weak self] in
      self?.pagingController.cancelPendingPageSwitch()
    })
    stack.addArrangedSubview(buttonRow)
    view.addSubview(stack)

    NSLayoutConstraint.activate([
      pagingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      pagingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pagingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pagingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5),

      stack.topAnchor.constraint(equalTo: pagingController.view.bottomAnchor, constant: 8),
      stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),

      logView.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      logView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    FKPagingDemoSupport.appendLog("Tab scope: only tab taps defer. Swipe/All also gate swipes.", to: logView)
  }

  private func scopeLabel(for index: Int) -> String {
    switch index {
    case 1: return "swipePagingOnly"
    case 2: return "all"
    default: return "tabSelectionOnly"
    }
  }

  private func labeledRow(title: String, control: UIView) -> UIStackView {
    let row = UIStackView()
    row.spacing = 8
    let label = UILabel()
    label.text = title
    label.font = .preferredFont(forTextStyle: .subheadline)
    row.addArrangedSubview(label)
    row.addArrangedSubview(UIView())
    row.addArrangedSubview(control)
    return row
  }

  func pagingController(
    _ controller: FKPagingController,
    shouldSwitchTo index: Int,
    reason: FKPagingSwitchReason
  ) -> Bool {
    guard blockSwitches else { return true }
    FKPagingDemoSupport.appendLog("blocked \(reason) → @\(index)", to: logView)
    return false
  }

  func pagingController(
    _ controller: FKPagingController,
    didRequestPageSwitchTo index: Int,
    reason: FKPagingSwitchReason
  ) {
    FKPagingDemoSupport.appendLog("pending @\(index) reason=\(reason)", to: logView)
  }

  func pagingControllerDidCancelPendingPageSwitch(_ controller: FKPagingController) {
    FKPagingDemoSupport.appendLog("pending cancelled", to: logView)
  }

  func pagingController(_ controller: FKPagingController, didSettleAt index: Int) {
    FKPagingDemoSupport.appendLog("settled @\(index)", to: logView)
  }
}
