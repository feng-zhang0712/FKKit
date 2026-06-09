import FKUIKit
import UIKit

/// Ten-step header with horizontal scroll and edge fade.
final class FKFlowCompactScrollableExampleViewController: FKFlowVisualizationScrollViewController {

  private let indicator: FKStepIndicator = {
    var config = FKStepIndicatorPresets.onboarding()
    config.layout.maxVisibleSteps = 5
    config.layout.stepSpacing = 12
    config.appearance.showsScrollEdgeFade = true
    config.layout.titleNumberOfLines = 1
    return FKStepIndicator(configuration: config)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Scrollable"

    indicator.items = FKFlowVisualizationExampleSupport.manyStepTitles(count: 10)
    indicator.currentStepIndex = 6

    let jump = FKFlowVisualizationExampleSupport.primaryButton(title: "Scroll to step 3", action: UIAction { [weak self] _ in
      guard let self else { return }
      self.indicator.scrollToStep(2, animated: true)
    })

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: "10 compact steps")
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "When steps exceed `maxVisibleSteps` or available width, content scrolls horizontally. Edge fade hints at off-screen steps."
    ))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedStepIndicator(indicator, minHeight: 72))
    box.addArrangedSubview(jump)
    contentStack.addArrangedSubview(box)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !didInitialScroll else { return }
    didInitialScroll = true
    // Start focused on the current step so "Scroll to step 3" visibly moves backward.
    indicator.scrollToStep(6, animated: false)
  }

  private var didInitialScroll = false
}
