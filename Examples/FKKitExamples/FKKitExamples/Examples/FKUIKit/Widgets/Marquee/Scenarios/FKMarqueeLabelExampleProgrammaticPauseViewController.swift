import FKUIKit
import UIKit

final class FKMarqueeLabelExampleProgrammaticPauseViewController: FKMarqueeLabelExampleScrollViewController {

  private let marquee = FKMarqueeLabel(text: FKMarqueeLabelExampleSupport.sampleLongText)
  private let pauseSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Programmatic pause"

    marquee.configuration.animation.delay = 0.25
    pauseSwitch.addAction(UIAction { [weak self] _ in self?.applyPause() }, for: .valueChanged)

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "isPaused")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.caption(
      "Hosts can freeze the ticker during modal presentation or user focus changes. Clearing isPaused resumes without re-applying animation.delay."
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.marqueeTrack(marquee))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(title: "Pause scrolling", control: pauseSwitch))
    contentStack.addArrangedSubview(box)
  }

  private func applyPause() {
    marquee.isPaused = pauseSwitch.isOn
  }
}
