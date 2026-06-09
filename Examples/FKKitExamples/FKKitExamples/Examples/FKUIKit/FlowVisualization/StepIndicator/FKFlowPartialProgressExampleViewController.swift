import FKUIKit
import UIKit

/// ``FKStepIndicator/currentStepProgress`` and ``FKStepIndicator/isLoading`` on the active step.
final class FKFlowPartialProgressExampleViewController: FKFlowVisualizationScrollViewController {

  private let indicator: FKStepIndicator = {
    var config = FKStepIndicatorConfiguration()
    config.layout.showsPartialConnectorFill = true
    return FKStepIndicator(configuration: config, items: FKFlowVisualizationExampleSupport.checkoutItems(), currentStepIndex: 2)
  }()

  private var progressTimer: Timer?
  private var simulatedProgress: CGFloat = 0
  private let progressLabel = UILabel()
  private let loadingSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Partial progress"

    progressLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
    progressLabel.text = "Connector progress: 0%"

    loadingSwitch.addAction(UIAction { [weak self] _ in
      guard let self else { return }
      self.indicator.isLoading = self.loadingSwitch.isOn
      if self.loadingSwitch.isOn {
        self.stopSimulation()
      }
    }, for: .valueChanged)

    let simulate = FKFlowVisualizationExampleSupport.primaryButton(title: "Simulate upload", action: UIAction { [weak self] _ in
      self?.startSimulation()
    })

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: "Upload on payment step")
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "`showsPartialConnectorFill` draws progress on the connector after the current step. `isLoading` shows a spinner on the current node and disables selection."
    ))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedStepIndicator(indicator))
    box.addArrangedSubview(progressLabel)
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.labeledRow(title: "Loading", control: loadingSwitch))
    box.addArrangedSubview(simulate)
    contentStack.addArrangedSubview(box)
  }

  private func startSimulation() {
    loadingSwitch.isOn = false
    indicator.isLoading = false
    simulatedProgress = 0
    progressTimer?.invalidate()
    progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
      guard let self else {
        timer.invalidate()
        return
      }
      MainActor.assumeIsolated {
        self.advanceSimulation()
      }
    }
  }

  private func advanceSimulation() {
    simulatedProgress += 0.02
    indicator.currentStepProgress = simulatedProgress
    indicator.layoutIfNeeded()
    progressLabel.text = String(format: "Connector progress: %.0f%%", simulatedProgress * 100)
    if simulatedProgress >= 1 {
      progressTimer?.invalidate()
      progressTimer = nil
      indicator.currentStepProgress = 0
      indicator.setCurrentStep(3, animated: true)
      progressLabel.text = "Upload complete — advanced to Done"
    }
  }

  private func stopSimulation() {
    progressTimer?.invalidate()
    progressTimer = nil
    progressLabel.text = "Loading — connector progress paused"
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopSimulation()
  }
}
