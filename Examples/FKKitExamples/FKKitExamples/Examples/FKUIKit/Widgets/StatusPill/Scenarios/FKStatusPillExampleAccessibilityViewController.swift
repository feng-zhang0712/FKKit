import FKUIKit
import UIKit

final class FKStatusPillExampleAccessibilityViewController: FKStatusPillExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Accessibility"

    let defaultPill = FKStatusPillExampleSupport.makePill(title: "Shipped", style: .success)

    var customConfig = FKStatusPillConfiguration()
    customConfig.accessibility.customLabel = "Order shipped and left the warehouse"
    let custom = FKStatusPillExampleSupport.makePill(
      title: "Shipped",
      style: .success,
      configuration: customConfig
    )

    var plainConfig = FKStatusPillConfiguration()
    plainConfig.accessibility.includesStatusSuffix = false
    let plain = FKStatusPillExampleSupport.makePill(
      title: "Cancelled",
      style: .error,
      configuration: plainConfig
    )

    let box = FKStatusPillExampleSupport.sectionContainer(title: "VoiceOver labels")
    box.addArrangedSubview(FKStatusPillExampleSupport.caption(
      "Default label uses fkuikit.status.a11y.label (“{title}, status”). customLabel overrides entirely. includesStatusSuffix = false reads title only."
    ))
    box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: "Default suffix", pill: defaultPill))
    box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: "customLabel", pill: custom))
    box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: "No suffix", pill: plain))
    contentStack.addArrangedSubview(box)
  }
}
