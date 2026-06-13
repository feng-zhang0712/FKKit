import FKUIKit
import UIKit

final class FKStatusPillExampleWithDotViewController: FKStatusPillExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "With leading dot"

    let withoutDot = FKStatusPillExampleSupport.makePill(title: "Delivered", style: .success)
    let withDot = FKStatusPillExampleSupport.makePill(title: "In transit", style: .info, showsDot: true)

    var customSpacing = FKStatusPillConfiguration()
    customSpacing.layout.dotSpacing = 10
    customSpacing.layout.dotDiameter = 10
    let wideGap = FKStatusPillExampleSupport.makePill(
      title: "Awaiting pickup",
      style: .warning,
      showsDot: true,
      configuration: customSpacing
    )

    let box = FKStatusPillExampleSupport.sectionContainer(title: "showsDot")
    box.addArrangedSubview(FKStatusPillExampleSupport.caption(
      "Leading 8 pt dot (configurable via layout.dotDiameter) with layout.dotSpacing before the title. Dot tint follows style foreground or dotColorOverride."
    ))
    box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: "No dot", pill: withoutDot))
    box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: "Default dot", pill: withDot))
    box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: "10 pt / 10 pt gap", pill: wideGap))
    contentStack.addArrangedSubview(box)
  }
}
