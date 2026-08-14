import FKUIKit
import UIKit

/// checkbox.indeterminateTap — promote vs cycle.
final class FKCheckboxExampleIndeterminateTapViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Indeterminate tap"

    let promoteBox = FKSelectionExampleSupport.sectionContainer(title: "promoteToChecked (default)")
    promoteBox.addArrangedSubview(FKSelectionExampleSupport.caption("Tap mixed → checked → unchecked → checked…"))
    let promote = FKCheckbox(title: "Parent folder", checkState: .indeterminate)
    promote.configuration.interaction.indeterminateTapBehavior = .promoteToChecked
    let (promoteStatus, updatePromote) = FKSelectionExampleSupport.statusLabel(prefix: "State")
    promote.onStateChanged = { updatePromote(String(describing: $0)) }
    updatePromote(String(describing: promote.checkState))
    promoteBox.addArrangedSubview(FKSelectionExampleSupport.embedControl(promote))
    promoteBox.addArrangedSubview(promoteStatus)
    contentStack.addArrangedSubview(promoteBox)

    let cycleBox = FKSelectionExampleSupport.sectionContainer(title: "cycle")
    cycleBox.addArrangedSubview(FKSelectionExampleSupport.caption("unchecked → checked → indeterminate → unchecked"))
    let cycle = FKCheckbox(title: "Cycle demo", checkState: .unchecked)
    cycle.configuration.interaction.indeterminateTapBehavior = .cycle
    let (cycleStatus, updateCycle) = FKSelectionExampleSupport.statusLabel(prefix: "State")
    cycle.onStateChanged = { updateCycle(String(describing: $0)) }
    updateCycle(String(describing: cycle.checkState))
    cycleBox.addArrangedSubview(FKSelectionExampleSupport.embedControl(cycle))
    cycleBox.addArrangedSubview(cycleStatus)
    contentStack.addArrangedSubview(cycleBox)
  }
}
