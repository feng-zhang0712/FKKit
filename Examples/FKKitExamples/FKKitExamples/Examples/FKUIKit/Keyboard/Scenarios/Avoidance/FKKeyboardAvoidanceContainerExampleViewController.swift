import UIKit
import FKUIKit

/// ``FKKeyboardAvoidanceStrategy/adjustContainer`` translates a card upward.
final class FKKeyboardAvoidanceContainerExampleViewController: UIViewController {
  private let card = UIView()
  private let field = FKKeyboardExampleUI.makeTextField(placeholder: "Focus me")
  private var avoidance: FKKeyboardAvoidanceController?
  private var dismissController: FKKeyboardDismissController?
  private let metrics = FKKeyboardExampleUI.monospaceLabel()
  private var isMetricsActive = false

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Container translate"
    view.backgroundColor = .systemGroupedBackground
    dismissController = FKKeyboardExampleUI.installTapToDismiss(on: view)

    let intro = FKKeyboardExampleUI.caption(
      "adjustContainer translates this fixed card just enough for the focused field to clear the keyboard. Do not aim this strategy at a full-screen UIScrollView."
    )
    intro.translatesAutoresizingMaskIntoConstraints = false

    card.backgroundColor = .secondarySystemGroupedBackground
    card.layer.cornerRadius = 12
    card.translatesAutoresizingMaskIntoConstraints = false

    let stack = FKKeyboardExampleUI.cardStack()
    stack.addArrangedSubview(FKKeyboardExampleUI.headline("Fixed card"))
    stack.addArrangedSubview(field)
    stack.addArrangedSubview(metrics)
    card.addSubview(stack)

    view.addSubview(intro)
    view.addSubview(card)

    NSLayoutConstraint.activate([
      intro.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
      intro.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      intro.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

      card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      card.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),

      stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
      stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
    ])

    let controller = FKKeyboardAvoidanceController(
      hostView: view,
      configuration: .init(strategy: .adjustContainer)
    )
    controller.containerView = card
    avoidance = controller
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    avoidance?.start()
    isMetricsActive = true
    tickMetrics()
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    isMetricsActive = false
    avoidance?.stop()
    dismissController?.stop()
  }

  private func tickMetrics() {
    guard isMetricsActive else { return }
    metrics.text = "appliedTranslationY: \(String(format: "%.1f", avoidance?.appliedTranslationY ?? 0))"
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
      self?.tickMetrics()
    }
  }
}
