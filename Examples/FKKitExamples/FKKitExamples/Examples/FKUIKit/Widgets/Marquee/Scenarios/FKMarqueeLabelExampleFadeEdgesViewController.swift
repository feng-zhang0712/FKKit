import FKUIKit
import UIKit

final class FKMarqueeLabelExampleFadeEdgesViewController: FKMarqueeLabelExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Fade edges"

    var fadedConfig = FKMarqueeLabelConfiguration()
    fadedConfig.animation.fadeWidth = 24
    fadedConfig.animation.delay = 0.3
    let faded = FKMarqueeLabel(configuration: fadedConfig, text: FKMarqueeLabelExampleSupport.sampleLongText)

    var plainConfig = FKMarqueeLabelConfiguration()
    plainConfig.animation.fadeWidth = 0
    plainConfig.animation.delay = 0.3
    let plain = FKMarqueeLabel(configuration: plainConfig, text: FKMarqueeLabelExampleSupport.sampleLongText)

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "animation.fadeWidth")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.caption(
      "Leading and trailing gradient masks soften hard clip edges. Set fadeWidth to 0 to disable."
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(
      title: "Fade 24pt",
      control: FKMarqueeLabelExampleSupport.marqueeTrack(faded)
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(
      title: "No fade",
      control: FKMarqueeLabelExampleSupport.marqueeTrack(plain)
    ))
    contentStack.addArrangedSubview(box)
  }
}
