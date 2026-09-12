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
      body: "Default: pins the focused field just above the keyboard when focus moves (no forced pull-down at the top). Set alignsFocusedViewToKeyboard = false for minimum-only movement. Switch fields while the keyboard is up — the scroller follows."
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
