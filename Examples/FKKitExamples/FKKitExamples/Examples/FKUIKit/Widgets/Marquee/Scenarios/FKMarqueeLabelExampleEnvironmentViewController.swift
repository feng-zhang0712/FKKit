import FKUIKit
import UIKit

final class FKMarqueeLabelExampleEnvironmentViewController: FKMarqueeLabelExampleScrollViewController {

  private let marquee = FKMarqueeLabel(text: FKMarqueeLabelExampleSupport.sampleLongText)
  private let rtlSwitch = UISwitch()
  private let mirrorSwitch = UISwitch()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "RTL & appearance"

    marquee.configuration.animation.delay = 0.25
    mirrorSwitch.isOn = true

    rtlSwitch.addAction(UIAction { [weak self] _ in self?.applyRTL() }, for: .valueChanged)
    mirrorSwitch.addAction(UIAction { [weak self] _ in self?.applyMirror() }, for: .valueChanged)

    let styleControl = UISegmentedControl(items: ["System", "Light", "Dark"])
    styleControl.selectedSegmentIndex = 0
    styleControl.addAction(UIAction { [weak self] action in
      guard let self, let seg = action.sender as? UISegmentedControl else { return }
      switch seg.selectedSegmentIndex {
      case 1: self.overrideUserInterfaceStyle = .light
      case 2: self.overrideUserInterfaceStyle = .dark
      default: self.overrideUserInterfaceStyle = .unspecified
      }
    }, for: .valueChanged)

    let box = FKMarqueeLabelExampleSupport.sectionContainer(title: "Layout direction & color")
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.caption(
      "animation.mirrorsDirectionInRTL (default true) flips scroll direction under RTL. Compare forced RTL with mirroring on vs off."
    ))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.marqueeTrack(marquee))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(title: "Force RTL", control: rtlSwitch))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(title: "Mirror in RTL", control: mirrorSwitch))
    box.addArrangedSubview(FKMarqueeLabelExampleSupport.labeledRow(title: "Interface style", control: styleControl))
    contentStack.addArrangedSubview(box)
  }

  private func applyRTL() {
    let attribute: UISemanticContentAttribute = rtlSwitch.isOn ? .forceRightToLeft : .unspecified
    view.semanticContentAttribute = attribute
    marquee.semanticContentAttribute = attribute
  }

  private func applyMirror() {
    var config = marquee.configuration
    config.animation.mirrorsDirectionInRTL = mirrorSwitch.isOn
    marquee.configuration = config
  }
}
