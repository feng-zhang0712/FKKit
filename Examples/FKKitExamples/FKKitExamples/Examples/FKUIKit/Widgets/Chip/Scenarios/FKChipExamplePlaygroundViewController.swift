import FKUIKit
import UIKit

final class FKChipExamplePlaygroundViewController: FKChipExampleScrollViewController {

  private let chip = FKChip(mode: .filter, title: "Playground")
  private let sizeControl = UISegmentedControl(items: ["XS", "S", "M"])
  private let cornerControl = UISegmentedControl(items: ["Capsule", "Fixed"])
  private let borderSwitch = UISwitch()
  private let hapticSwitch = UISwitch()
  private let highlightSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Playground"

    chip.leadingIcon = .symbol(name: "line.3.horizontal.decrease")
    chip.isSelected = true

    sizeControl.selectedSegmentIndex = 2
    cornerControl.selectedSegmentIndex = 0
    borderSwitch.isOn = false
    hapticSwitch.isOn = false
    highlightSwitch.isOn = true

    [sizeControl, cornerControl].forEach {
      $0.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)
    }
    [borderSwitch, hapticSwitch, highlightSwitch].forEach {
      $0.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)
    }

    let box = FKChipExampleSupport.sectionContainer(title: "Live preview")
    box.addArrangedSubview(FKChipExampleSupport.embedChip(chip))
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Size", control: sizeControl))
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Corner", control: cornerControl))
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Border when selected", control: borderSwitch))
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Haptic on selection", control: hapticSwitch))
    box.addArrangedSubview(FKChipExampleSupport.labeledRow(title: "Highlight on press", control: highlightSwitch))

    contentStack.addArrangedSubview(box)
    applyConfiguration()
  }

  private func applyConfiguration() {
    var config = FKChipConfiguration()
    config.layout.size = resolvedSize()
    config.appearance.cornerStyle = cornerControl.selectedSegmentIndex == 0 ? .capsule : .fixed(8)
    config.appearance.usesBorderWhenSelected = borderSwitch.isOn
    config.interaction.hapticFeedbackOnSelection = hapticSwitch.isOn
    config.interaction.highlightsOnPress = highlightSwitch.isOn
    chip.configuration = config
  }

  private func resolvedSize() -> FKChipSize {
    switch sizeControl.selectedSegmentIndex {
    case 0: .xs
    case 1: .s
    default: .m
    }
  }
}
