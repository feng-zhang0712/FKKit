import FKUIKit
import UIKit

/// Read-only checkout header driven by ``FKStepIndicator/currentStepIndex``.
final class FKFlowCheckoutStepsExampleViewController: FKFlowVisualizationScrollViewController {

  private let indicator = FKStepIndicator(configuration: FKStepIndicatorPresets.checkout())
  private let statusLabel = UILabel()
  private var stepIndex = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Checkout"

    indicator.items = FKFlowVisualizationExampleSupport.checkoutItems()
    indicator.currentStepIndex = stepIndex
    updateStatus()

    let back = FKFlowVisualizationExampleSupport.primaryButton(title: "Back", action: UIAction { [weak self] _ in
      self?.moveStep(by: -1)
    })
    let next = FKFlowVisualizationExampleSupport.primaryButton(title: "Next", action: UIAction { [weak self] _ in
      self?.moveStep(by: 1)
    })

    let controls = UIStackView(arrangedSubviews: [back, next])
    controls.axis = .horizontal
    controls.spacing = 12
    controls.distribution = .fillEqually

    statusLabel.font = .preferredFont(forTextStyle: .body)
    statusLabel.textAlignment = .center
    statusLabel.numberOfLines = 0

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: "Checkout progress")
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "Uses `FKStepIndicatorPresets.checkout()` with index-driven states. Read-only — no step taps."
    ))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedStepIndicator(indicator))
    box.addArrangedSubview(statusLabel)
    box.addArrangedSubview(controls)
    contentStack.addArrangedSubview(box)
  }

  private func moveStep(by delta: Int) {
    let maxIndex = indicator.items.count - 1
    stepIndex = min(max(0, stepIndex + delta), maxIndex)
    indicator.setCurrentStep(stepIndex, animated: true)
    updateStatus()
  }

  private func updateStatus() {
    guard let index = indicator.currentStepIndex, index < indicator.items.count else { return }
    let item = indicator.items[index]
    statusLabel.text = "Current step: \(item.title) (index \(index))"
  }
}
