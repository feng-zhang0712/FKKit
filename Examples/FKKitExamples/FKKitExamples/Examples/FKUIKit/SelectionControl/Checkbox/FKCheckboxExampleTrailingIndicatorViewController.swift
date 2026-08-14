import FKUIKit
import UIKit

/// checkbox.trailingIndicator.
final class FKCheckboxExampleTrailingIndicatorViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Trailing indicator"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Settings style")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("indicatorEdge = .trailing places the box after the title."))

    for title in ["Wi-Fi calling", "Low Power Mode", "Background App Refresh"] {
      let checkbox = FKCheckbox(title: title, checkState: title == "Wi-Fi calling" ? .checked : .unchecked)
      checkbox.configuration.layout.indicatorEdge = .trailing
      box.addArrangedSubview(FKSelectionExampleSupport.embedControl(checkbox))
    }
    contentStack.addArrangedSubview(box)
  }
}
