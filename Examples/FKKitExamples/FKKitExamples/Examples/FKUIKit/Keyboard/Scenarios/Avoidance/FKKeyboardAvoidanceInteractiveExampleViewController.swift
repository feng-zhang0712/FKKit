import UIKit
import FKUIKit

/// ``FKKeyboardAvoidanceStrategy/interactive`` on a scrollable form.
///
/// The controller falls back to content-inset avoidance for `UIScrollView` targets (transforming a
/// full-screen scroll view would leave a large blank band above the keyboard).
final class FKKeyboardAvoidanceInteractiveExampleViewController: FKKeyboardExamplePageViewController {
  private var avoidance: FKKeyboardAvoidanceController?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Interactive strategy"
    addIntro(
      title: "interactive → insets fallback",
      body: "Strategy is .interactive, but the host is a scroll view, so FKKeyboardAvoidanceController applies content insets + focus scrolling (never translates the scroll view)."
    )
    addTallSpacer(multiplicity: 5)
    addField(title: "Chat-like reply", field: FKKeyboardExampleUI.makeTextField(placeholder: "Message"))
    addTallSpacer(multiplicity: 3)
    addField(title: "Second reply", field: FKKeyboardExampleUI.makeTextField(placeholder: "Another field near the bottom"))

    let controller = FKKeyboardAvoidanceController(
      hostView: view,
      configuration: .init(
        strategy: .interactive,
        additionalBottomInset: 12,
        subtractSafeAreaBottom: true
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
