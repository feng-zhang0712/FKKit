import FKUIKit
import UIKit

/// Interactive onboarding header — tap completed steps to go back.
final class FKFlowOnboardingWizardExampleViewController: FKFlowVisualizationScrollViewController {

  private let indicator = FKStepIndicator(configuration: FKStepIndicatorPresets.onboarding())
  private let statusLabel = UILabel()
  private var stepIndex = 2

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Onboarding"

    indicator.items = FKFlowVisualizationExampleSupport.onboardingItems()
    indicator.currentStepIndex = stepIndex
    indicator.onStepSelected = { [weak self] index, item in
      self?.stepIndex = index
      self?.indicator.setCurrentStep(index, animated: true)
      self?.statusLabel.text = "Jumped back to “\(item.title)” (index \(index))"
    }
    updateStatus()

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: "Wizard header")
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "Completed steps are tappable (`selectableStates: [.completed]`, haptic on select). Compact dots layout with horizontal scroll when needed."
    ))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedStepIndicator(indicator, minHeight: 72))
    box.addArrangedSubview(statusLabel)
    contentStack.addArrangedSubview(box)

    statusLabel.font = .preferredFont(forTextStyle: .body)
    statusLabel.numberOfLines = 0
    statusLabel.textColor = .secondaryLabel
  }

  private func updateStatus() {
    statusLabel.text = "Current step index: \(stepIndex). Tap a completed dot to navigate back."
  }
}
