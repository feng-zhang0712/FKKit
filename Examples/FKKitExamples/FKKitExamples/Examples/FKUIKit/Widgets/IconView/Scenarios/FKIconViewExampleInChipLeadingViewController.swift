import FKUIKit
import UIKit

final class FKIconViewExampleInChipLeadingViewController: FKIconViewExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "In chip leading"

    let payload: FKWidgetIcon = .symbol(name: "sparkles")

    var iconConfig = FKIconViewConfiguration()
    iconConfig.layout.size = .s
    iconConfig.appearance.defaultTintColor = .systemPurple
    let standalone = FKIconView(configuration: iconConfig)
    standalone.applyWidgetIcon(payload)
    standalone.iconTintColor = .systemPurple

    let chip = FKChip(mode: .filter, title: "Featured")
    chip.leadingIcon = payload
    chip.isSelected = true
    chip.translatesAutoresizingMaskIntoConstraints = false

    let tag = FKTag(title: "New", variant: .brand)
    tag.leadingIcon = FKTagIcon.symbol(name: "tag.fill")

    let box = FKIconViewExampleSupport.sectionContainer(title: "Shared FKWidgetIcon payload")
    box.addArrangedSubview(FKIconViewExampleSupport.caption(
      "Chip and Tag resolve leading icons through the same FKWidgetIcon DTO. FKIconView.applyWidgetIcon(_:) uses the shared renderer for standalone icon containers."
    ))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "FKIconView (.s)", control: standalone))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "FKChip filter", control: chip))
    box.addArrangedSubview(FKIconViewExampleSupport.labeledRow(title: "FKTag", control: tag))

    contentStack.addArrangedSubview(box)
  }
}
