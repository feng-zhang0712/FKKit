import FKUIKit
import UIKit

final class FKCopyChipExampleToastViewController: FKCopyChipExampleScrollViewController {

  private let chip = FKCopyChip()
  private let hapticSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Toast success"

    chip.text = "INV-2024-00821"
    chip.copyText = "INV-2024-00821"

    hapticSwitch.addAction(UIAction { [weak self] _ in self?.applyFeedback() }, for: .valueChanged)

    let box = FKCopyChipExampleSupport.sectionContainer(title: "FKToast on copy")
    box.addArrangedSubview(FKCopyChipExampleSupport.caption(
      "Default toast message from FKUIKitI18n. Toggle haptic to enable playsHapticWithToast alongside the banner."
    ))
    box.addArrangedSubview(FKCopyChipExampleSupport.embedChip(chip))
    box.addArrangedSubview(FKCopyChipExampleSupport.labeledRow(title: "Haptic + toast", control: hapticSwitch))

    contentStack.addArrangedSubview(box)
    applyFeedback()
  }

  private func applyFeedback() {
    var config = FKCopyChipConfiguration()
    config.feedback.mode = .toast
    config.feedback.playsHapticWithToast = hapticSwitch.isOn
    config.feedback.toastMessage = "Invoice number copied"
    chip.configuration = config
  }
}
