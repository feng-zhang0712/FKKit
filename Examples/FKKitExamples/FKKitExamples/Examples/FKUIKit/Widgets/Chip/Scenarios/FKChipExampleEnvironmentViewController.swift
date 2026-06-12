import FKUIKit
import UIKit

final class FKChipExampleEnvironmentViewController: FKChipExampleScrollViewController {

  private let chipGroup = FKChipGroup()
  private let tagRow = FKChipExampleSupport.intrinsicWidthRow(spacing: 8)
  private let rtlSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL & appearance"

    var groupConfig = FKChipGroupConfiguration()
    groupConfig.chipMode = .filter
    groupConfig.layoutMode = .flow()

    chipGroup.configuration = groupConfig
    chipGroup.chips = [
      FKChipItem(id: "1", title: "Featured", leadingIcon: .symbol(name: "star.fill"), isSelected: true),
      FKChipItem(id: "2", title: "Trending", leadingIcon: .symbol(name: "chart.line.uptrend.xyaxis")),
      FKChipItem(id: "3", title: "For you"),
    ]
    chipGroup.selectionMode = .single

    let tags: [(String, FKTagVariant)] = [
      ("Promo", .brand),
      ("Limited", .warning),
      ("Verified", .success),
    ]
    tags.forEach { spec in
      let tag = FKTag(title: spec.0, variant: spec.1)
      tagRow.addItem(tag)
    }

    rtlSwitch.addAction(UIAction { [weak self] _ in self?.applyRTL() }, for: .valueChanged)

    let styleControl = UISegmentedControl(items: ["System", "Light", "Dark"])
    styleControl.selectedSegmentIndex = 0
    styleControl.addAction(UIAction { [weak self] action in
      guard let self, let seg = action.sender as? UISegmentedControl else { return }
      switch seg.selectedSegmentIndex {
      case 1: self.overrideUserInterfaceStyle = .light
      case 2: self.overrideUserInterfaceStyle = .dark
      default: self.overrideUserInterfaceStyle = .unspecified
      }
    }, for: .valueChanged)

    let box = FKChipExampleSupport.sectionContainer(title: "Layout direction & color")
    box.addArrangedSubview(FKChipExampleSupport.caption(
      "Chip groups and tags mirror under forced RTL. Toggle light/dark to inspect variant contrast and outline tags."
    ))
    box.addArrangedSubview(FKChipExampleSupport.embedGroup(chipGroup))
    box.addArrangedSubview(tagRow)
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Force RTL", control: rtlSwitch))
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Interface style", control: styleControl))

    contentStack.addArrangedSubview(box)
  }

  private func applyRTL() {
    let attribute: UISemanticContentAttribute = rtlSwitch.isOn ? .forceRightToLeft : .unspecified
    view.semanticContentAttribute = attribute
    chipGroup.semanticContentAttribute = attribute
    tagRow.semanticContentAttribute = attribute
    tagRow.subviews.forEach { $0.semanticContentAttribute = attribute }
  }
}
