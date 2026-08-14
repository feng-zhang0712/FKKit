import FKUIKit
import UIKit

/// radio.button.states — four design states.
final class FKRadioButtonExampleStatesViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Radio button states"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Design states")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Standalone radios do not enforce mutual exclusion — use FKRadioGroup for that."))

    let off = FKRadioButton(title: "Default", isSelected: false)
    let on = FKRadioButton(title: "Selected", isSelected: true)
    let disabled = FKRadioButton(title: "Disabled", isSelected: false)
    disabled.isEnabled = false
    let disabledOn = FKRadioButton(title: "Disabled + On", isSelected: true)
    disabledOn.isEnabled = false

    for control in [off, on, disabled, disabledOn] {
      box.addArrangedSubview(FKSelectionExampleSupport.embedControl(control))
    }
    contentStack.addArrangedSubview(box)
  }
}
