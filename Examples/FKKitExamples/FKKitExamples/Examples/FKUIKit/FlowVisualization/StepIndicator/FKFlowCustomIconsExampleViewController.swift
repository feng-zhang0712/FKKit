import FKUIKit
import UIKit

/// Custom ``FKFlowStepIcon`` overrides per step.
final class FKFlowCustomIconsExampleViewController: FKFlowVisualizationScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom icons"

    let items: [FKFlowStepItem] = [
      FKFlowStepItem(id: "cart", title: "Cart", state: .completed, icon: .systemName("cart.fill")),
      FKFlowStepItem(id: "address", title: "Address", state: .completed, icon: .systemName("house.fill")),
      FKFlowStepItem(id: "pay", title: "Payment", state: .current, icon: .number(3)),
      FKFlowStepItem(id: "done", title: "Done", state: .upcoming, icon: .systemName("gift.fill")),
    ]

    let indicator = FKStepIndicator(items: items)

    let defaultsBox = FKFlowVisualizationExampleSupport.sectionContainer(title: "State defaults")
    let defaultItems: [FKFlowStepItem] = [
      FKFlowStepItem(id: "c", title: "Completed", state: .completed),
      FKFlowStepItem(id: "u", title: "Current", state: .current),
      FKFlowStepItem(id: "a", title: "Upcoming", state: .upcoming),
      FKFlowStepItem(id: "e", title: "Error", state: .error),
    ]
    let defaultsIndicator = FKStepIndicator(items: defaultItems)
    defaultsBox.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "When `icon` is nil, glyphs follow state (checkmark, number, circle, exclamation)."
    ))
    defaultsBox.addArrangedSubview(FKFlowVisualizationExampleSupport.embedStepIndicator(defaultsIndicator, minHeight: 80))
    contentStack.addArrangedSubview(defaultsBox)

    let customBox = FKFlowVisualizationExampleSupport.sectionContainer(title: "SF Symbols & numbers")
    customBox.addArrangedSubview(FKFlowVisualizationExampleSupport.caption(
      "Use `.systemName`, `.number`, `.imageAsset`, or `.template` to override defaults."
    ))
    customBox.addArrangedSubview(FKFlowVisualizationExampleSupport.embedStepIndicator(indicator))
    contentStack.addArrangedSubview(customBox)
  }
}
