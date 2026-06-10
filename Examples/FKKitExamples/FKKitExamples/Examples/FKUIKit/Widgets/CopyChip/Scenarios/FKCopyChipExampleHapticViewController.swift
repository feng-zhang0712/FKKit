import FKUIKit
import UIKit

final class FKCopyChipExampleHapticViewController: FKCopyChipExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Haptic only"

    var config = FKCopyChipConfiguration()
    config.feedback.mode = .hapticOnly
    config.feedback.postsAccessibilityAnnouncement = false
    config.feedback.playsSuccessFlash = true

    let chip = FKCopyChip(
      configuration: config,
      text: "TKT-8842",
      copyText: "TKT-8842-support-case"
    )

    let box = FKCopyChipExampleSupport.sectionContainer(title: "hapticOnly")
    box.addArrangedSubview(FKCopyChipExampleSupport.caption(
      "Light impact on copy without FKToast. Success flash still plays unless Reduce Motion is enabled."
    ))
    box.addArrangedSubview(FKCopyChipExampleSupport.embedChip(chip))

    contentStack.addArrangedSubview(box)
  }
}
