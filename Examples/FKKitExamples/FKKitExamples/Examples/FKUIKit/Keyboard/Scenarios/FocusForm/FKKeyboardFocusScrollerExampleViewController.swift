import UIKit
import FKUIKit

/// ``FKKeyboardFocusScroller`` keeps lower fields visible when the keyboard is up.
final class FKKeyboardFocusScrollerExampleViewController: FKKeyboardExamplePageViewController {
  private var scroller: FKKeyboardFocusScroller?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Focus scroller"
    addIntro(
      title: "Scroll first responder into view",
      body: "Default: pins the focused field just above the keyboard when focus moves; does not force pull-down when already at the top. Set alignsFocusedViewToKeyboard = false for minimum-only movement."
    )
    addTallSpacer(multiplicity: 10)
    addField(title: "Name", field: FKKeyboardExampleUI.makeTextField(placeholder: "Top"))
    addTallSpacer(multiplicity: 6)
    addField(title: "City", field: FKKeyboardExampleUI.makeTextField(placeholder: "Middle"))
    addTallSpacer(multiplicity: 6)
    addField(title: "Postal code", field: FKKeyboardExampleUI.makeTextField(placeholder: "Bottom — tap after keyboard is up"))

    scroller = FKKeyboardFocusScroller(
      rootView: view,
      scrollView: scrollView,
      configuration: .init(additionalTopInset: 20, keyboardDistanceFromFocusedView: 20)
    )
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    scroller?.start()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    scroller?.stop()
  }
}
