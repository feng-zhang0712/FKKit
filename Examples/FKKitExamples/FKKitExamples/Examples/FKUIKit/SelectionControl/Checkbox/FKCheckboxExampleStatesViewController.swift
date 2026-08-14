import FKUIKit
import UIKit

/// checkbox.states — five design states.
final class FKCheckboxExampleStatesViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Checkbox states"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Design states")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Interactive rows show Default / Checked / Indeterminate. Disabled rows show Disabled and Disabled+On."))

    let unchecked = FKCheckbox(title: "Default (unchecked)")
    let checked = FKCheckbox(title: "Checked", checkState: .checked)
    let indeterminate = FKCheckbox(title: "Indeterminate (mixed)", checkState: .indeterminate)
    let disabled = FKCheckbox(title: "Disabled", checkState: .unchecked)
    disabled.isEnabled = false
    let disabledOn = FKCheckbox(title: "Disabled + On", checkState: .checked)
    disabledOn.isEnabled = false

    for control in [unchecked, checked, indeterminate, disabled, disabledOn] {
      box.addArrangedSubview(FKSelectionExampleSupport.embedControl(control))
    }
    contentStack.addArrangedSubview(box)
  }
}
