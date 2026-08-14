import FKUIKit
import UIKit

/// radio.group.error.
final class FKRadioGroupExampleErrorViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Group error"

    var configuration = FKRadioGroupConfiguration()
    configuration.interaction.allowsEmptySelection = true
    let group = FKRadioGroup(configuration: configuration, options: FKSelectionExampleSupport.billingOptions())
    group.onSelectionChanged = { [weak group] id in
      if id != nil { group?.showsError = false }
    }

    let box = FKSelectionExampleSupport.sectionContainer(title: "Required selection")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("showsError tints the card border until the host clears it after a valid choice."))
    box.addArrangedSubview(group)
    box.addArrangedSubview(FKSelectionExampleSupport.makeButton(title: "Validate") { [weak group] in
      group?.showsError = group?.selectedOptionID == nil
    })
    contentStack.addArrangedSubview(box)
  }
}
