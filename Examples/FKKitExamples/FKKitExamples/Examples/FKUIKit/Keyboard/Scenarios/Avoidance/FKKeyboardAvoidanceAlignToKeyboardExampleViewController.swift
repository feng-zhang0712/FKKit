import UIKit
import FKUIKit

/// Default pin-to-keyboard (no forced pull-down when already at the top).
final class FKKeyboardAvoidanceAlignToKeyboardExampleViewController: FKKeyboardExamplePageViewController {
  private var avoidance: FKKeyboardAvoidanceController?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Align to keyboard"
    addIntro(
      title: "Pin focused field to keyboard",
      body: "Default: switching fields always adjusts offset so the field sits just above the keyboard. Fields already at the top are not pulled further down with extra top inset."
    )
    addTallSpacer(multiplicity: 5)
    addField(title: "Field", field: FKKeyboardExampleUI.makeTextField(placeholder: "Tap fields above/below"))
    addTallSpacer(multiplicity: 4)

    let controller = FKKeyboardAvoidanceController(
      hostView: view,
      configuration: .init(strategy: .adjustContentInsets)
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
