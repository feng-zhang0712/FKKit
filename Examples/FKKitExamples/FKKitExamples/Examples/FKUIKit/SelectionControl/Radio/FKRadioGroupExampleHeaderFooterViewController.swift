import FKUIKit
import UIKit

/// radio.group.headerFooter.
final class FKRadioGroupExampleHeaderFooterViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Header & footer"

    let group = FKRadioGroup(options: FKSelectionExampleSupport.billingOptions())
    group.headerTitle = "BILLING PERIOD"
    group.footerTitle = "You can change this later in Account → Subscription."
    group.selectedOptionID = "year"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Outside the card")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Header and footer titles sit outside the insetGrouped chrome by default."))
    box.addArrangedSubview(group)
    contentStack.addArrangedSubview(box)
  }
}
