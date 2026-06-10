import FKUIKit
import UIKit

final class FKCopyChipExampleMonospacedViewController: FKCopyChipExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Monospaced tracking"

    var config = FKCopyChipConfiguration()
    config.layout.size = .s
    config.layout.truncation = .tail(maxCharacters: 14)
    config.appearance.usesMonospacedFont = true
    config.appearance.copySymbolName = "square.on.square"
    config.feedback.mode = .toast

    let chip = FKCopyChip(
      configuration: config,
      text: FKCopyChipExampleSupport.sampleTrackingNumber,
      copyText: FKCopyChipExampleSupport.sampleTrackingNumber
    )

    let box = FKCopyChipExampleSupport.sectionContainer(title: "Logistics tracking number")
    box.addArrangedSubview(FKCopyChipExampleSupport.caption(
      "Size S (28 pt), monospaced font, tail truncation, and square.on.square icon. copyText preserves the full carrier tracking ID."
    ))
    box.addArrangedSubview(FKCopyChipExampleSupport.embedChip(chip))

    contentStack.addArrangedSubview(box)
  }
}
