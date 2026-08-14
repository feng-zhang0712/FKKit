import FKUIKit
import UIKit

/// radio.group.disabledOption.
final class FKRadioGroupExampleDisabledOptionViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Disabled option"

    let options = [
      FKRadioOption(id: "available", title: "Available plan", subtitle: "Selectable"),
      FKRadioOption(id: "soldout", title: "Sold out", subtitle: "Disabled option", isEnabled: false),
      FKRadioOption(id: "locked", title: "Enterprise (locked)", subtitle: "Contact sales", isEnabled: false),
    ]
    let group = FKRadioGroup(options: options)
    group.selectedOptionID = "soldout"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Mixed availability")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Selected disabled option renders Disabled+On. Taps on disabled rows are ignored."))
    box.addArrangedSubview(group)
    contentStack.addArrangedSubview(box)
  }
}
