import FKUIKit
import UIKit

/// radio.group.insetGrouped — billing period card.
final class FKRadioGroupExampleInsetGroupedViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Inset grouped"

    let group = FKRadioGroup(options: FKSelectionExampleSupport.billingOptions())
    group.selectedOptionID = "month"
    let (status, update) = FKSelectionExampleSupport.statusLabel(prefix: "Selected")
    group.onSelectionChanged = { id in update(id ?? "nil") }
    update(group.selectedOptionID ?? "nil")

    let box = FKSelectionExampleSupport.sectionContainer(title: "Billing period")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Default insetGrouped style: rounded card, row separators, mutual exclusion."))
    box.addArrangedSubview(group)
    box.addArrangedSubview(status)
    contentStack.addArrangedSubview(box)
  }
}
