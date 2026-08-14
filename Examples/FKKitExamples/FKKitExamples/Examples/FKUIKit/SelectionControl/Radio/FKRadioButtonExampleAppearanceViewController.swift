import FKUIKit
import UIKit

/// radio.button.sizes / tints.
final class FKRadioButtonExampleAppearanceViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Sizes & tints"

    let sizes = FKSelectionExampleSupport.sectionContainer(title: "Sizes")
    for (size, label) in [(FKSelectionControlSize.small, "Small"), (.medium, "Medium"), (.large, "Large")] {
      let radio = FKRadioButton(title: label, isSelected: true)
      radio.configuration.layout.size = size
      sizes.addArrangedSubview(FKSelectionExampleSupport.embedControl(radio))
    }
    contentStack.addArrangedSubview(sizes)

    let tints = FKSelectionExampleSupport.sectionContainer(title: "Tints")
    for (tint, title) in [(.blue, "Blue"), (.green, "Green"), (.red, "Red"), (.orange, "Orange"), (.purple, "Purple")] as [(FKSelectionControlTint, String)] {
      let radio = FKRadioButton(title: title, isSelected: true)
      radio.configuration.appearance.tint = tint
      tints.addArrangedSubview(FKSelectionExampleSupport.embedControl(radio))
    }
    contentStack.addArrangedSubview(tints)
  }
}
