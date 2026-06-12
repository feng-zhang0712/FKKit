import FKUIKit
import UIKit

final class FKCopyChipExamplePlaygroundViewController: FKCopyChipExampleScrollViewController {

  private let chip = FKCopyChip()
  private let sizeControl = UISegmentedControl(items: ["S", "M"])
  private let cornerControl = UISegmentedControl(items: ["Capsule", "Fixed"])
  private let symbolControl = UISegmentedControl(items: ["doc.on.doc", "square.on.square"])
  private let flashSwitch = UISwitch()
  private let enabledSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Playground"

    chip.text = "PLAY-001"
    chip.copyText = "PLAY-001-demo-token"

    sizeControl.selectedSegmentIndex = 1
    cornerControl.selectedSegmentIndex = 0
    symbolControl.selectedSegmentIndex = 0
    flashSwitch.isOn = true
    enabledSwitch.isOn = true

    [sizeControl, cornerControl, symbolControl].forEach {
      $0.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)
    }
    flashSwitch.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)
    enabledSwitch.addAction(UIAction { [weak self] action in
      guard let self, let sw = action.sender as? UISwitch else { return }
      self.chip.isEnabled = sw.isOn
    }, for: .valueChanged)

    let box = FKCopyChipExampleSupport.sectionContainer(title: "Live preview")
    box.addArrangedSubview(FKCopyChipExampleSupport.embedChip(chip))
    box.addArrangedSubview(FKCopyChipExampleSupport.labeledRow(title: "Size", control: sizeControl))
    box.addArrangedSubview(FKCopyChipExampleSupport.labeledRow(title: "Corner", control: cornerControl))
    box.addArrangedSubview(FKCopyChipExampleSupport.labeledRow(title: "Copy icon", control: symbolControl))
    box.addArrangedSubview(FKCopyChipExampleSupport.labeledRow(title: "Success flash", control: flashSwitch))
    box.addArrangedSubview(FKCopyChipExampleSupport.labeledRow(title: "Enabled", control: enabledSwitch))

    contentStack.addArrangedSubview(box)
    applyConfiguration()
  }

  private func applyConfiguration() {
    var config = FKCopyChipConfiguration()
    config.layout.size = sizeControl.selectedSegmentIndex == 0 ? .s : .m
    config.appearance.cornerStyle = cornerControl.selectedSegmentIndex == 0 ? .capsule : .fixed(8)
    config.appearance.copySymbolName = symbolControl.selectedSegmentIndex == 0 ? "doc.on.doc" : "square.on.square"
    config.feedback.mode = .toast
    config.feedback.playsSuccessFlash = flashSwitch.isOn
    chip.configuration = config
  }
}
