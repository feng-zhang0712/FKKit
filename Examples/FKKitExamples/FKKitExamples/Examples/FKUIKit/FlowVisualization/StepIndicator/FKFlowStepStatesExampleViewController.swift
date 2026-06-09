import FKUIKit
import UIKit

/// Every ``FKFlowStepState`` with explicit item states (no index driver).
final class FKFlowStepStatesExampleViewController: FKFlowVisualizationScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Step states"

    let items: [FKFlowStepItem] = [
      FKFlowStepItem(id: "done", title: "Completed", subtitle: "Checkmark node", state: .completed),
      FKFlowStepItem(id: "now", title: "Current", subtitle: "Emphasized title", state: .current),
      FKFlowStepItem(id: "next", title: "Upcoming", subtitle: "Muted connector", state: .upcoming),
      FKFlowStepItem(id: "fail", title: "Error", subtitle: "Payment failed", state: .error),
      FKFlowStepItem(id: "skip", title: "Skipped", subtitle: "KYC bypassed", state: .skipped),
      FKFlowStepItem(id: "off", title: "Disabled", subtitle: "Not available", state: .disabled),
    ]

    var config = FKStepIndicatorConfiguration()
    config.layout.stepSpacing = 4
    config.layout.titleNumberOfLines = 1
    config.appearance.showsScrollEdgeFade = true
    let indicator = FKStepIndicator(configuration: config, items: items)

    let box = FKFlowVisualizationExampleSupport.sectionContainer(title: "Explicit states")
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "Each item sets its own `state`. Skipped titles use strikethrough; disabled steps reduce opacity."
    ))
    box.addArrangedSubview(FKFlowVisualizationExampleSupport.embedStepIndicator(indicator, minHeight: 96))
    contentStack.addArrangedSubview(box)

    let resolverBox = FKFlowVisualizationExampleSupport.sectionContainer(title: "FKFlowProgressResolver")
    let active = FKFlowProgressResolver.activeIndex(in: items) ?? -1
    resolverBox.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "`activeIndex(in:)` returns \(active) (first `.current`, else first `.upcoming`, else last `.completed`)."
    ))
    contentStack.addArrangedSubview(resolverBox)
  }
}
