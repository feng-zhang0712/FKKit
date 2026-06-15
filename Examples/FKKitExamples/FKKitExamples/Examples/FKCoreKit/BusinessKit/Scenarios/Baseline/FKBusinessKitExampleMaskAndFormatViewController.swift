import UIKit
import FKCoreKit

/// B7 — mask, number, and time business formatters.
final class FKBusinessKitExampleMaskAndFormatViewController: FKBusinessKitExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "MaskAndFormat"
    addActionButton("Run formatters + mask") { [weak self] in
      guard let self else { return }
      let now = Date()
      self.appendLog("Relative: \(self.kit.utils.time.relativeDescription(from: now.addingTimeInterval(-135), now: now))")
      self.appendLog("Fixed: \(self.kit.utils.time.format(date: now, format: "yyyy-MM-dd HH:mm", locale: nil))")
      self.appendLog("Amount: \(self.kit.utils.number.formatAmount(1234567.89, fractionDigits: 2))")
      self.appendLog("Compact: \(self.kit.utils.number.formatCompact(12_345_678, fractionDigits: 1))")
      self.appendLog("Phone: \(self.kit.utils.mask.maskPhone("13800138000"))")
      self.appendLog("ID: \(self.kit.utils.mask.maskIDCard("110101199001011234"))")
      self.appendLog("Email: \(self.kit.utils.mask.maskEmail("name@example.com"))")
    }
  }
}
