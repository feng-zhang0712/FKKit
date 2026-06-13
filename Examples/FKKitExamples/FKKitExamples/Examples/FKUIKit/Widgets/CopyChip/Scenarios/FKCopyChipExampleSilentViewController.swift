import FKUIKit
import UIKit

final class FKCopyChipExampleSilentViewController: FKCopyChipExampleScrollViewController {

  private let logLabel = FKCopyChipExampleSupport.eventLogLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Silent copy"

    var config = FKCopyChipConfiguration()
    config.feedback.mode = .none

    let chip = FKCopyChip(
      configuration: config,
      text: FKCopyChipExampleSupport.sampleOrderID,
      copyText: FKCopyChipExampleSupport.sampleOrderID
    )
    chip.onCopy = { [weak self] copied in
      self?.logLabel.text = "Copied silently · pasteboard: \"\(copied)\""
    }

    let box = FKCopyChipExampleSupport.sectionContainer(title: "feedback.none")
    box.addArrangedSubview(FKCopyChipExampleSupport.caption(
      "No toast, haptic, background flash, or VoiceOver announcement when feedback.mode is .none. Useful in dense forms or when the host shows its own confirmation."
    ))
    box.addArrangedSubview(FKCopyChipExampleSupport.embedChip(chip))
    box.addArrangedSubview(logLabel)

    contentStack.addArrangedSubview(box)
  }
}
