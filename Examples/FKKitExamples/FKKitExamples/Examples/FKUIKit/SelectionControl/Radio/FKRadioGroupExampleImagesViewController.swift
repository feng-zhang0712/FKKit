import FKUIKit
import UIKit

/// radio.group.images.
final class FKRadioGroupExampleImagesViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Option images"

    let group = FKRadioGroup(options: FKSelectionExampleSupport.paymentOptionsWithImages())
    group.selectedOptionID = "card"
    let (status, update) = FKSelectionExampleSupport.statusLabel(prefix: "Selected")
    group.onSelectionChanged = { id in update(id ?? "nil") }
    update(group.selectedOptionID ?? "nil")

    let box = FKSelectionExampleSupport.sectionContainer(title: "Payment method")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Images sit between the indicator and title when indicatorEdge is leading."))
    box.addArrangedSubview(group)
    box.addArrangedSubview(status)
    contentStack.addArrangedSubview(box)
  }
}
