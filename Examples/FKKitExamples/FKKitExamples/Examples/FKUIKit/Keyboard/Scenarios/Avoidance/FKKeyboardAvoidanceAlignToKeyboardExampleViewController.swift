import UIKit
import FKUIKit

/// Opt-out of pin-to-keyboard: ``FKKeyboardAvoidanceConfiguration/alignsFocusedViewToKeyboard`` = `false`.
final class FKKeyboardAvoidanceAlignToKeyboardExampleViewController: FKKeyboardExamplePageViewController {
  private var avoidance: FKKeyboardAvoidanceController?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Minimum movement"
    addIntro(
      title: "alignsFocusedViewToKeyboard = false",
      body: "Only scrolls when the focused field would be covered by the keyboard. Compare with Content insets (default pin) — fields that are already clear do not move."
    )
    addTallSpacer(multiplicity: 5)
    addField(title: "Upper field", field: FKKeyboardExampleUI.makeTextField(placeholder: "Already clear — should not jump"))
    addTallSpacer(multiplicity: 4)
    addField(title: "Lower field", field: FKKeyboardExampleUI.makeTextField(placeholder: "Covered — scrolls just enough"))

    let controller = FKKeyboardAvoidanceController(
      hostView: view,
      configuration: .init(
        strategy: .adjustContentInsets,
        alignsFocusedViewToKeyboard: false
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
