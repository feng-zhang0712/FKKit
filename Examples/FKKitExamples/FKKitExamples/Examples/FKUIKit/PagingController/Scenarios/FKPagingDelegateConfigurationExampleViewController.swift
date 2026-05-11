import UIKit
import FKUIKit

/// Explores swipe toggles, gesture policies, tab alignment, and delegate telemetry.
@MainActor
final class FKPagingDelegateConfigurationExampleViewController: UIViewController, FKPagingControllerDelegate {
  private let pagingController: FKPagingController
  private let logView = UITextView()

  init() {
    let tabs = FKTabBarExampleSupport.makeItems(4)
    let pages: [UIViewController] = [
      FKPagingDemoPageViewController(color: .systemTeal, titleText: "Alpha"),
      FKPagingDemoPageViewController(color: .systemIndigo, titleText: "Beta"),
      FKPagingDemoListViewController(headerTitle: "Gamma list"),
      FKPagingDemoPageViewController(color: .systemPink, titleText: "Delta"),
    ]
    pagingController = FKPagingController(
      tabs: tabs,
      viewControllers: pages,
      configuration: FKPagingConfiguration(
        tabAlignment: .alwaysCenter
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
    title = "Delegate & config"
    view.backgroundColor = .systemGroupedBackground

    addChild(pagingController)
    pagingController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(pagingController.view)
    pagingController.didMove(toParent: self)

    logView.translatesAutoresizingMaskIntoConstraints = false
    logView.isEditable = false
    logView.font = .monospacedDigitSystemFont(ofSize: 11, weight: .regular)
    logView.backgroundColor = .secondarySystemGroupedBackground
    logView.layer.cornerRadius = 8
    logView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    view.addSubview(logView)

    let controls = buildControls()
    controls.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(controls)

    NSLayoutConstraint.activate([
      pagingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      pagingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      pagingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      pagingController.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.52),

      controls.topAnchor.constraint(equalTo: pagingController.view.bottomAnchor, constant: 8),
      controls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      controls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),

      logView.topAnchor.constraint(equalTo: controls.bottomAnchor, constant: 8),
      logView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
      logView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
      logView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
    ])

    appendLog("Ready — observe phases, progress while dragging, and settlement.")
  }

  private func buildControls() -> UIView {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 10

    let swipeRow = UIStackView()
    swipeRow.spacing = 8
    let swipeLabel = UILabel()
    swipeLabel.text = "Swipe paging"
    swipeLabel.font = .preferredFont(forTextStyle: .subheadline)
    let swipeSwitch = UISwitch()
    swipeSwitch.isOn = pagingController.configuration.allowsSwipePaging
    swipeSwitch.addAction(UIAction { [weak self] action in
      guard let self, let toggle = action.sender as? UISwitch else { return }
      pagingController.configuration.allowsSwipePaging = toggle.isOn
      appendLog("allowsSwipePaging = \(toggle.isOn)")
    }, for: .valueChanged)
    swipeRow.addArrangedSubview(swipeLabel)
    swipeRow.addArrangedSubview(UIView())
    swipeRow.addArrangedSubview(swipeSwitch)

    let gestureLabel = UILabel()
    gestureLabel.text = "Gesture policy"
    gestureLabel.font = .preferredFont(forTextStyle: .subheadline)
    let gestureControl = UISegmentedControl(items: ["Exclusive", "Prefer pop"])
    gestureControl.selectedSegmentIndex = 1
    gestureControl.addAction(UIAction { [weak self] action in
      guard let self, let control = action.sender as? UISegmentedControl else { return }
      switch control.selectedSegmentIndex {
      case 0: pagingController.configuration.gesturePolicy = .exclusive
      default:
        pagingController.configuration.gesturePolicy = .preferNavigationBackGesture(edgeWidth: 28)
      }
      appendLog("gesturePolicy updated")
    }, for: .valueChanged)

    stack.addArrangedSubview(swipeRow)
    stack.addArrangedSubview(gestureLabel)
    stack.addArrangedSubview(gestureControl)

    return stack
  }

  private func appendLog(_ line: String) {
    logView.text += line + "\n"
    let bottom = NSRange(location: logView.text.count - 1, length: 1)
    logView.scrollRangeToVisible(bottom)
  }

  func pagingController(_ controller: FKPagingController, didChangePhase phase: FKPagingPhase) {
    appendLog("phase → \(phase) | transitionActive=\(controller.isTransitionActive)")
  }

  func pagingController(_ controller: FKPagingController, didUpdateProgress progress: CGFloat, from fromIndex: Int, to toIndex: Int) {
    appendLog(String(format: "progress %.2f  %d → %d", progress, fromIndex, toIndex))
  }

  func pagingController(_ controller: FKPagingController, didSettleAt index: Int) {
    appendLog("settled @ \(index)")
  }
}
