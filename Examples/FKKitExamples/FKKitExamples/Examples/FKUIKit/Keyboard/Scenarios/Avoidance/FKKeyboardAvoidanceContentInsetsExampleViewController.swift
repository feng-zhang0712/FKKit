import UIKit
import FKUIKit

/// ``FKKeyboardAvoidanceStrategy/adjustContentInsets`` on a scroll view.
final class FKKeyboardAvoidanceContentInsetsExampleViewController: FKKeyboardExamplePageViewController {
  private var avoidance: FKKeyboardAvoidanceController?
  private let metrics = FKKeyboardExampleUI.monospaceLabel()
  private var isMetricsActive = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Content insets"
    addIntro(
      title: "adjustContentInsets",
      body: "Adds keyboard overlap to contentInset / indicator insets, then scrolls only when the focused field would be covered (default). Enable alignsFocusedViewToKeyboard to always pin to the keyboard. Switch fields while the keyboard is up — the scroller should follow when needed."
    )
    contentStack.addArrangedSubview(metrics)
    addTallSpacer(multiplicity: 6)
    addField(title: "Email", field: FKKeyboardExampleUI.makeTextField(placeholder: "name@example.com", keyboardType: .emailAddress))
    addField(title: "Notes", field: FKKeyboardExampleUI.makeTextView(placeholderHint: "Long notes"))
    addTallSpacer(multiplicity: 4)
    addField(title: "Bottom field", field: FKKeyboardExampleUI.makeTextField(placeholder: "Near the bottom"))

    let controller = FKKeyboardAvoidanceController(
      hostView: view,
      configuration: .init(strategy: .adjustContentInsets, additionalBottomInset: 8)
    )
    controller.scrollView = scrollView
    avoidance = controller
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    avoidance?.start()
    isMetricsActive = true
    refreshMetrics()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    isMetricsActive = false
    avoidance?.stop()
  }

  private func refreshMetrics() {
    guard isMetricsActive else { return }
    metrics.text = "appliedBottomInset: \(String(format: "%.1f", avoidance?.appliedBottomInset ?? 0))"
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
      self?.refreshMetrics()
    }
  }
}
