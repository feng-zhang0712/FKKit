import FKUIKit
import UIKit

final class FKMarqueeLabelExampleDragToPauseViewController: FKMarqueeLabelExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Drag to pause"

    var config = FKMarqueeLabelConfiguration()
    config.interaction.pausesOnPan = true
    config.animation.delay = 0.25

    let marquee = FKMarqueeLabel(configuration: config, text: FKMarqueeLabelExampleSupport.sampleLongText)
    let track = FKMarqueeLabelExampleSupport.marqueeTrack(marquee, backgroundColor: .secondarySystemGroupedBackground)

    let panOffSwitch = UISwitch()
    panOffSwitch.addAction(UIAction { [weak marquee] action in
      guard let marquee, let toggle = action.sender as? UISwitch else { return }
      var updated = marquee.configuration
      updated.interaction.pausesOnPan = !toggle.isOn
      marquee.configuration = updated
    }, for: .valueChanged)

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "interaction.pausesOnPan")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.caption(
      "Touch and hold (or drag) on the ticker to pause scrolling. Release to resume immediately without the initial delay."
    ))
    box.addArrangedSubview(track)
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(title: "Disable pan pause", control: panOffSwitch))
    contentStack.addArrangedSubview(box)
  }
}
