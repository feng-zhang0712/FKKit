import FKUIKit
import UIKit

final class FKMarqueeLabelExampleShortTextViewController: FKMarqueeLabelExampleScrollViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Short text alignment"

    var leadingConfig = FKMarqueeLabelConfiguration()
    leadingConfig.layout.alignment = .leading
    let leading = FKMarqueeLabel(configuration: leadingConfig, text: FKMarqueeLabelExampleSupport.sampleShortText)

    var centerConfig = FKMarqueeLabelConfiguration()
    centerConfig.layout.alignment = .center
    let centered = FKMarqueeLabel(configuration: centerConfig, text: FKMarqueeLabelExampleSupport.sampleShortText)

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "No scroll when text fits")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.caption(
      "Short copy stays static. Choose .leading or .center alignment via FKMarqueeLabelLayoutConfiguration."
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(
      title: "Leading",
      control: FKMarqueeLabelExampleSupport.marqueeTrack(leading)
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(
      title: "Center",
      control: FKMarqueeLabelExampleSupport.marqueeTrack(centered)
    ))
    contentStack.addArrangedSubview(box)
  }
}
