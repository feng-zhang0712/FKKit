import FKUIKit
import UIKit

final class FKCopyChipExampleOrderIDViewController: FKCopyChipExampleScrollViewController {

  private let chip = FKCopyChip()
  private let logLabel = FKCopyChipExampleSupport.eventLogLabel()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Order ID"

    var config = FKCopyChipConfiguration()
    config.layout.prefix = "Order #"
    config.layout.truncation = .middle(prefixLength: 5, suffixLength: 3)
    config.feedback.mode = .toast

    chip.configuration = config
    chip.text = FKCopyChipExampleSupport.sampleOrderID
    chip.copyText = FKCopyChipExampleSupport.sampleOrderID
    chip.onCopy = { [weak self] copied in
      self?.appendLog("onCopy · \"\(copied)\"\npasteboard: \(FKCopyChipExampleSupport.pasteboardPreview())")
    }

    let box = FKCopyChipExampleSupport.sectionContainer(title: "Middle truncation + full copy")
    box.addArrangedSubview(FKCopyChipExampleSupport.caption(
      "Display shows \"Order #A1288…1D\" while the pasteboard receives the full \(FKCopyChipExampleSupport.sampleOrderID.count)-character ID via copyText."
    ))
    box.addArrangedSubview(FKCopyChipExampleSupport.embedChip(chip))
    box.addArrangedSubview(logLabel)

    contentStack.addArrangedSubview(box)
  }

  private func appendLog(_ line: String) {
    logLabel.text = line
  }
}
