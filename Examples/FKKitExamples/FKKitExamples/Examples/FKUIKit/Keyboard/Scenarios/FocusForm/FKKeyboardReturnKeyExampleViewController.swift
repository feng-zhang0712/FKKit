import UIKit
import FKUIKit

/// ``FKKeyboardFormNavigator/handleReturn(from:)`` from `textFieldShouldReturn`.
final class FKKeyboardReturnKeyExampleViewController: FKKeyboardExamplePageViewController, UITextFieldDelegate {
  private let navigator = FKKeyboardFormNavigator()
  private let fields: [UITextField] = [
    FKKeyboardExampleUI.makeTextField(placeholder: "Field 1 — Return → next"),
    FKKeyboardExampleUI.makeTextField(placeholder: "Field 2 — Return → next"),
    FKKeyboardExampleUI.makeTextField(placeholder: "Field 3 — Return → resign"),
  ]
  private var avoidance: FKKeyboardAvoidanceController?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Return key"
    addIntro(
      title: "handleReturn(from:)",
      body: "Wire textFieldShouldReturn to navigator.handleReturn. Last field resigns focus."
    )
    for (index, field) in fields.enumerated() {
      field.delegate = self
      field.returnKeyType = index == fields.count - 1 ? .done : .next
      addField(title: "Field \(index + 1)", field: field)
    }
    navigator.fields = fields

    let toolbar = FKKeyboardToolbar()
    toolbar.install(asAccessoryOn: fields)
    toolbar.attach(to: navigator)

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
    navigator.stopFocusTracking()
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    _ = navigator.handleReturn(from: textField)
    return true
  }
}
