import UIKit
import FKUIKit

/// Baseline with ``FKKeyboardAvoidanceStrategy/disabled``.
final class FKKeyboardAvoidanceDisabledExampleViewController: FKKeyboardExamplePageViewController {
  private var avoidance: FKKeyboardAvoidanceController?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Disabled strategy"
    addIntro(
      title: "No avoidance",
      body: "Strategy .disabled leaves layout unchanged on purpose. Focus a bottom field to see the keyboard cover content — contrast with Content insets / Container demos. Tap empty area to dismiss."
    )
    addTallSpacer(multiplicity: 10)
    addField(title: "Covered field", field: FKKeyboardExampleUI.makeTextField(placeholder: "Will be hidden by the keyboard"))

    let controller = FKKeyboardAvoidanceController(
      hostView: view,
      configuration: .init(strategy: .disabled)
    )
    controller.scrollView = scrollView
    avoidance = controller
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    avoidance?.start()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    avoidance?.stop()
  }
}
