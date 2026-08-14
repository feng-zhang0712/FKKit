import FKUIKit
import UIKit

/// radio.trailingIndicator.
final class FKRadioButtonExampleTrailingIndicatorViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Trailing indicator"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Trailing edge")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("indicatorEdge = .trailing for Settings-style radio rows."))

    for (title, selected) in [("Standard", true), ("Express", false), ("Overnight", false)] {
      let radio = FKRadioButton(title: title, isSelected: selected)
      radio.configuration.layout.indicatorEdge = .trailing
      box.addArrangedSubview(FKSelectionExampleSupport.embedControl(radio))
    }
    contentStack.addArrangedSubview(box)
  }
}
