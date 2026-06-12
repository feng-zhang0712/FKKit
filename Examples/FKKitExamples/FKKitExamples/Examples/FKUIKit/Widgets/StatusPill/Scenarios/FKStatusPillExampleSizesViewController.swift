import FKUIKit
import UIKit

final class FKStatusPillExampleSizesViewController: FKStatusPillExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Size tiers"

    var smallConfig = FKStatusPillConfiguration()
    smallConfig.layout.size = .s
    let small = FKStatusPillExampleSupport.makePill(
      title: "Shipped",
      style: .success,
      showsDot: true,
      configuration: smallConfig
    )

    var mediumConfig = FKStatusPillConfiguration()
    mediumConfig.layout.size = .m
    mediumConfig.appearance.textStyle = .footnote
    let medium = FKStatusPillExampleSupport.makePill(
      title: "Out for delivery",
      style: .info,
      showsDot: true,
      configuration: mediumConfig
    )

    let box = FKStatusPillExampleSupport.sectionContainer(title: "FKStatusPillSize")
    box.addArrangedSubview(FKStatusPillExampleSupport.caption(
      ".s (28 pt) is the default list-trailing density. .m (32 pt) emphasizes detail screens; fonts scale with height via FKStatusPillRenderer."
    ))
    box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: "S · 28 pt", pill: small))
    box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: "M · 32 pt", pill: medium))
    contentStack.addArrangedSubview(box)
  }
}
