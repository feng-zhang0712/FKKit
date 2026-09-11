import UIKit
import FKUIKit

/// Form navigator + toolbar install / attach / focus tracking.
final class FKKeyboardFormNavigatorToolbarExampleViewController: FKKeyboardExamplePageViewController {
  private let navigator = FKKeyboardFormNavigator()
  private let toolbar = FKKeyboardToolbar()
  private var avoidance: FKKeyboardAvoidanceController?
  private let status = FKKeyboardExampleUI.monospaceLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Navigator + toolbar"
    addIntro(
      title: "Prev / Next / Done",
      body: "toolbar.install(onFormRoot:navigator:) discovers fields, sets inputAccessoryView, attaches actions, and starts focus tracking."
    )
    contentStack.addArrangedSubview(status)
    addField(title: "First name", field: FKKeyboardExampleUI.makeTextField(placeholder: "Ada"))
    addField(title: "Last name", field: FKKeyboardExampleUI.makeTextField(placeholder: "Lovelace"))
    addField(title: "Email", field: FKKeyboardExampleUI.makeTextField(placeholder: "ada@example.com", keyboardType: .emailAddress))
    addField(title: "Bio", field: FKKeyboardExampleUI.makeTextView(placeholderHint: "Short bio"))

    // Register status updates before install so ``attach(to:)`` can chain them with toolbar enabling.
    navigator.onNavigationAvailabilityChange = { [weak self] canGoPrevious, canGoNext in
      guard let self else { return }
      self.status.text =
        "canGoPrevious=\(canGoPrevious)  canGoNext=\(canGoNext)  focusedIndex=\(String(describing: self.navigator.focusedIndex))"
    }
    toolbar.install(onFormRoot: contentStack, navigator: navigator)

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
}
