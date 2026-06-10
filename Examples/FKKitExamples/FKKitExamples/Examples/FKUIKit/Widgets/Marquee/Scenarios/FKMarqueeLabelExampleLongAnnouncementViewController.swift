import FKUIKit
import UIKit

final class FKMarqueeLabelExampleLongAnnouncementViewController: FKMarqueeLabelExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Long announcement"

    var config = FKMarqueeLabelConfiguration()
    config.animation.delay = 0.5
    config.appearance.textColor = .label

    let marquee = FKMarqueeLabel(configuration: config, text: FKMarqueeLabelExampleSupport.sampleLongText)

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "Looping ticker")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.caption(
      "Scrolling starts only when measured text width exceeds the track. Two labels recycle with loopGap for a seamless loop."
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.marqueeTrack(marquee))
    contentStack.addArrangedSubview(box)
  }
}
