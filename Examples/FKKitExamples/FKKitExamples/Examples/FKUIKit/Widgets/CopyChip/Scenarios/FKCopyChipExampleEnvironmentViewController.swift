import FKUIKit
import UIKit

final class FKCopyChipExampleEnvironmentViewController: FKCopyChipExampleScrollViewController {

  private let chip = FKCopyChip()
  private let rtlSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL & appearance"

    var config = FKCopyChipConfiguration()
    config.layout.prefix = "Order #"
    config.layout.truncation = .middle(prefixLength: 4, suffixLength: 3)
    config.accessibility.customLabel = "Copy order identifier"

    chip.configuration = config
    chip.text = FKCopyChipExampleSupport.sampleOrderID
    chip.copyText = FKCopyChipExampleSupport.sampleOrderID

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

    let box = FKCopyChipExampleSupport.sectionContainer(title: "Layout direction & color")
    box.addArrangedSubview(FKCopyChipExampleSupport.caption(
      "Capsule fill and icon tint adapt to light/dark. Force RTL to verify prefix + icon layout mirroring. Custom accessibilityLabel overrides the default \"Copy {summary}\" template."
    ))
    box.addArrangedSubview(FKCopyChipExampleSupport.embedChip(chip))
    box.addArrangedSubview(FKCopyChipExampleSupport.labeledRow(title: "Force RTL", control: rtlSwitch))
    box.addArrangedSubview(FKCopyChipExampleSupport.labeledRow(title: "Interface style", control: styleControl))

    contentStack.addArrangedSubview(box)
  }

  private func applyRTL() {
    let attribute: UISemanticContentAttribute = rtlSwitch.isOn ? .forceRightToLeft : .unspecified
    view.semanticContentAttribute = attribute
    chip.semanticContentAttribute = attribute
    chip.setNeedsLayout()
  }
}
