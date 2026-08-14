import FKUIKit
import UIKit

/// checkbox.sizes — SM / MD / LG.
final class FKCheckboxExampleSizesViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Checkbox sizes"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Indicator sizes")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("16 / 22 / 28 pt indicators (±0.5 pt design tokens)."))

    for (size, label) in [(FKSelectionControlSize.small, "Small (16)"), (.medium, "Medium (22)"), (.large, "Large (28)")] {
      let checkbox = FKCheckbox(title: label, checkState: .checked)
      checkbox.configuration.layout.size = size
      box.addArrangedSubview(FKSelectionExampleSupport.embedControl(checkbox))
    }
    contentStack.addArrangedSubview(box)
  }
}
