import UIKit
import FKUIKit

/// Feeds avoidance from a shared ``FKKeyboardObserver`` (`observesKeyboardAutomatically = false`).
final class FKKeyboardAvoidanceExternalFeedExampleViewController: FKKeyboardExamplePageViewController {
  private let sharedObserver = FKKeyboardObserver()
  private var avoidance: FKKeyboardAvoidanceController?
  private let status = FKKeyboardExampleUI.monospaceLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "External observer feed"
    addIntro(
      title: "Shared observer",
      body: "One FKKeyboardObserver drives avoidance via handleKeyboardInfo(_:). Use this when multiple controllers should share a single notification stream."
    )
    contentStack.addArrangedSubview(status)
    addTallSpacer(multiplicity: 5)
    addField(title: "Field", field: FKKeyboardExampleUI.makeTextField(placeholder: "Type here"))

    let controller = FKKeyboardAvoidanceController(
      hostView: view,
      configuration: .init(
        strategy: .adjustContentInsets,
        observesKeyboardAutomatically: false
      )
    )
    controller.scrollView = scrollView
    avoidance = controller

    sharedObserver.onChange = { [weak self] info in
      guard let self else { return }
      self.avoidance?.handleKeyboardInfo(info)
      self.status.text =
        "fed isVisible=\(info.isVisible) overlap=\(String(format: "%.1f", info.overlapHeight(in: self.view)))"
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    avoidance?.start()
    sharedObserver.start()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    sharedObserver.stop()
    avoidance?.stop()
  }
}
