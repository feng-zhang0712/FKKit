import FKUIKit
import UIKit

final class FKMarqueeLabelExampleAccessibilityViewController: FKMarqueeLabelExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Accessibility"

    var customConfig = FKMarqueeLabelConfiguration()
    customConfig.accessibility.customLabel =
      "Promotion: free express shipping on orders over fifty dollars through Sunday"
    customConfig.animation.delay = 0.25
    let custom = FKMarqueeLabel(configuration: customConfig, text: FKMarqueeLabelExampleSupport.sampleLongText)

    var frequentConfig = FKMarqueeLabelConfiguration()
    frequentConfig.accessibility.usesUpdatesFrequentlyTraitWhenScrolling = true
    frequentConfig.animation.delay = 0.25
    let frequent = FKMarqueeLabel(configuration: frequentConfig, text: FKMarqueeLabelExampleSupport.sampleLongText)

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "VoiceOver")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.caption(
      "Inner scroll labels are hidden from VoiceOver; the host reads full text once. customLabel overrides the default. usesUpdatesFrequentlyTraitWhenScrolling adds .updatesFrequently while actively scrolling — use sparingly."
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(
      title: "Custom label",
      control: FKMarqueeLabelExampleSupport.marqueeTrack(custom)
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(
      title: "Updates frequently",
      control: FKMarqueeLabelExampleSupport.marqueeTrack(frequent)
    ))
    contentStack.addArrangedSubview(box)
  }
}
