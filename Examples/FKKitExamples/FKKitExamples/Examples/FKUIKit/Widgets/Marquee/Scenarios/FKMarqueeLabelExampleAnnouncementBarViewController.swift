import FKUIKit
import UIKit

final class FKMarqueeLabelExampleAnnouncementBarViewController: FKMarqueeLabelExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Announcement bar"

    var config = FKMarqueeLabelConfiguration()
    config.appearance.textStyle = .footnote
    config.appearance.textColor = .systemOrange
    config.animation.speed = 32
    config.animation.fadeWidth = 12
    config.animation.delay = 0.75

    let marquee = FKMarqueeLabel(configuration: config, text: FKMarqueeLabelExampleSupport.sampleLongText)
    let bar = FKMarqueeLabelExampleSupport.announcementBar(marquee: marquee)

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "Promo strip")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.caption(
      "Common home-screen pattern: icon + constrained FKMarqueeLabel inside a tinted bar. Pin the bar to the safe area leading/trailing in production."
    ))
    box.addArrangedSubview(bar)
    contentStack.addArrangedSubview(box)
  }
}
