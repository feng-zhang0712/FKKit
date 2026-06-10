import FKUIKit
import UIKit

final class FKMarqueeLabelExamplePlaygroundViewController: FKMarqueeLabelExampleScrollViewController {

  private let marquee = FKMarqueeLabel(text: FKMarqueeLabelExampleSupport.sampleLongText)
  private let speedSlider = UISlider()
  private let gapSlider = UISlider()
  private let delaySlider = UISlider()
  private let directionControl = UISegmentedControl(items: ["Left", "Right"])
  private let styleControl = UISegmentedControl(items: ["Footnote", "Body", "Headline"])

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Animation playground"

    speedSlider.minimumValue = 12
    speedSlider.maximumValue = 72
    speedSlider.value = 36

    gapSlider.minimumValue = 8
    gapSlider.maximumValue = 64
    gapSlider.value = 32

    delaySlider.minimumValue = 0
    delaySlider.maximumValue = 3
    delaySlider.value = 0.5

    directionControl.selectedSegmentIndex = 0
    styleControl.selectedSegmentIndex = 0

    [speedSlider, gapSlider, delaySlider, directionControl, styleControl].forEach {
      $0.addAction(UIAction { [weak self] _ in self?.applyConfiguration() }, for: .valueChanged)
    }

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "Live preview")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.marqueeTrack(marquee))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(title: "Speed (pt/s)", control: speedSlider))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(title: "Loop gap", control: gapSlider))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(title: "Start delay (s)", control: delaySlider))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(title: "Direction", control: directionControl))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(title: "Text style", control: styleControl))
    contentStack.addArrangedSubview(box)

    applyConfiguration()
  }

  private func applyConfiguration() {
    var config = FKMarqueeLabelConfiguration()
    config.animation.speed = CGFloat(speedSlider.value)
    config.animation.loopGap = CGFloat(gapSlider.value)
    config.animation.delay = TimeInterval(delaySlider.value)
    config.animation.direction = directionControl.selectedSegmentIndex == 1 ? .right : .left
    config.animation.fadeWidth = 16
    config.appearance.textStyle = resolvedTextStyle()
    marquee.configuration = config
    marquee.text = FKMarqueeLabelExampleSupport.sampleLongText
  }

  private func resolvedTextStyle() -> UIFont.TextStyle {
    switch styleControl.selectedSegmentIndex {
    case 1: .body
    case 2: .headline
    default: .footnote
    }
  }
}
