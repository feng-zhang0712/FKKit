import FKUIKit
import UIKit

/// checkbox.tints — five tint presets.
final class FKCheckboxExampleTintsViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Checkbox tints"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Tint presets")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Checked fill uses tint; unchecked keeps a neutral border."))

    let pairs: [(FKSelectionControlTint, String)] = [
      (.blue, "Blue"), (.green, "Green"), (.red, "Red"), (.orange, "Orange"), (.purple, "Purple"),
    ]
    for (tint, title) in pairs {
      let checkbox = FKCheckbox(title: title, checkState: .checked)
      checkbox.configuration.appearance.tint = tint
      box.addArrangedSubview(FKSelectionExampleSupport.embedControl(checkbox))
    }
    contentStack.addArrangedSubview(box)
  }
}
