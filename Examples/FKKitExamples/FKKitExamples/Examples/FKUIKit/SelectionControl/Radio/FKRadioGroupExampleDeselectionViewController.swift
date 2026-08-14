import FKUIKit
import UIKit

/// radio.group.allowsDeselection.
final class FKRadioGroupExampleDeselectionViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Allows deselection"

    var configuration = FKRadioGroupConfiguration()
    configuration.interaction.allowsDeselection = true
    configuration.interaction.allowsEmptySelection = true
    let group = FKRadioGroup(configuration: configuration, options: FKSelectionExampleSupport.billingOptions())
    group.selectedOptionID = "week"
    let (status, update) = FKSelectionExampleSupport.statusLabel(prefix: "Selected")
    group.onSelectionChanged = { id in update(id ?? "nil") }
    update(group.selectedOptionID ?? "nil")

    let box = FKSelectionExampleSupport.sectionContainer(title: "Optional choice")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Tap the selected row again to clear when allowsDeselection and allowsEmptySelection are true."))
    box.addArrangedSubview(group)
    box.addArrangedSubview(status)
    contentStack.addArrangedSubview(box)
  }
}
