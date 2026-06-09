import FKUIKit
import UIKit

/// ``FKStepIndicatorDelegate`` and closure callbacks with a live event log.
final class FKFlowDelegateLogExampleViewController: FKFlowVisualizationScrollViewController, FKStepIndicatorDelegate {

  private let indicator: FKStepIndicator = {
    var config = FKStepIndicatorPresets.onboarding()
    config.interaction.hapticOnSelect = true
    return FKStepIndicator(configuration: config, items: FKFlowVisualizationExampleSupport.onboardingItems(), currentStepIndex: 3)
  }()

  private let logLabel = FKFlowVisualizationExampleSupport.monospacedLogLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Delegate log"

    indicator.delegate = self
    indicator.onStepSelected = { [weak self] index, item in
      FKFlowVisualizationExampleSupport.appendLog("onStepSelected(\(index), \"\(item.title)\")", to: self?.logLabel ?? UILabel())
    }

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: "Step indicator events")
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "Tap completed steps. `shouldSelectStepAt` returns `false` for step index 0 to demonstrate gating."
    ))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedStepIndicator(indicator, minHeight: 72))
    box.addArrangedSubview(logLabel)
    contentStack.addArrangedSubview(box)
  }

  func stepIndicator(_ indicator: FKStepIndicator, shouldSelectStepAt index: Int) -> Bool {
    index != 0
  }

  func stepIndicator(_ indicator: FKStepIndicator, didSelectStepAt index: Int) {
    FKFlowVisualizationExampleSupport.appendLog("delegate didSelectStepAt(\(index))", to: logLabel)
    indicator.setCurrentStep(index, animated: true)
  }
}
