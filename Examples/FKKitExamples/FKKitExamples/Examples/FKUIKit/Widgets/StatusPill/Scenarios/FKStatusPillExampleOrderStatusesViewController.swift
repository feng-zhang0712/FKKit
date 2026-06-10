import FKUIKit
import UIKit

final class FKStatusPillExampleOrderStatusesViewController: FKStatusPillExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Order status pills"

    let box = FKStatusPillExampleSupport.sectionContainer(title: "FKStatusPillStyle presets")
    box.addArrangedSubview(FKStatusPillExampleSupport.caption(
      "Workflow semantics use FKWidgetStatusColorTokens — distinct from FKTag marketing variants (brand, outline, etc.)."
    ))

    let rows: [(String, FKStatusPillStyle, String)] = [
      (".success", .success, "Shipped"),
      (".warning", .warning, "Pending review"),
      (".error", .error, "Payment failed"),
      (".info", .info, "Processing"),
      (".neutral", .neutral, "Draft"),
    ]

    rows.forEach { label, style, copy in
      box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(
        label: label,
        pill: FKStatusPillExampleSupport.makePill(title: copy, style: style)
      ))
    }

    contentStack.addArrangedSubview(box)
  }
}
