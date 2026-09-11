import UIKit
import FKUIKit

/// Opt-in IQ-style pin: ``FKKeyboardAvoidanceConfiguration/alignsFocusedViewToKeyboard``.
final class FKKeyboardAvoidanceAlignToKeyboardExampleViewController: FKKeyboardExamplePageViewController {
  private var avoidance: FKKeyboardAvoidanceController?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Align to keyboard"
    addIntro(
      title: "alignsFocusedViewToKeyboard = true",
      body: "Pins the focused field just above the keyboard even when it was already fully visible (IQKeyboardManager-like). Default avoidance uses minimum movement instead — compare with Content insets / External observer feed."
    )
    addTallSpacer(multiplicity: 5)
    addField(title: "Field", field: FKKeyboardExampleUI.makeTextField(placeholder: "Already clear of the keyboard"))
    addTallSpacer(multiplicity: 4)

    let controller = FKKeyboardAvoidanceController(
      hostView: view,
      configuration: .init(
        strategy: .adjustContentInsets,
        alignsFocusedViewToKeyboard: true
      )
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
