import FKUIKit
import UIKit

final class FKStatusPillExampleInfoPulseViewController: FKStatusPillExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Info pulse dot"

    var staticConfig = FKStatusPillConfiguration()
    staticConfig.appearance.pulsesDotForInfoStyle = false
    let staticDot = FKStatusPillExampleSupport.makePill(
      title: "Processing",
      style: .info,
      showsDot: true,
      configuration: staticConfig
    )

    var pulseConfig = FKStatusPillConfiguration()
    pulseConfig.appearance.pulsesDotForInfoStyle = true
    let pulsingDot = FKStatusPillExampleSupport.makePill(
      title: "Syncing",
      style: .info,
      showsDot: true,
      configuration: pulseConfig
    )

    let box = FKStatusPillExampleSupport.sectionContainer(title: "pulsesDotForInfoStyle")
    box.addArrangedSubview(FKStatusPillExampleSupport.caption(
      "Optional pulse uses the shared FKPresencePulseLayer (respects Reduce Motion). Default is off per design — enable only for active in-progress states."
    ))
    box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: "Static dot", pill: staticDot))
    box.addArrangedSubview(FKStatusPillExampleSupport.styleRow(label: "Pulsing dot", pill: pulsingDot))
    contentStack.addArrangedSubview(box)
  }
}
