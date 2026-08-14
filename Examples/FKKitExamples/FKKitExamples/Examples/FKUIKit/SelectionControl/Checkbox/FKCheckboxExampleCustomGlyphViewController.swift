import FKUIKit
import UIKit

/// checkbox.customGlyph.
final class FKCheckboxExampleCustomGlyphViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom glyphs"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Custom images")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Override checkmarkImage / indeterminateImage with SF Symbols or bitmaps."))

    let config = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
    let checked = FKCheckbox(title: "Heart checkmark", checkState: .checked)
    checked.configuration.appearance.tint = .red
    checked.configuration.appearance.checkmarkImage = UIImage(systemName: "heart.fill", withConfiguration: config)

    let mixed = FKCheckbox(title: "Custom minus", checkState: .indeterminate)
    mixed.configuration.appearance.tint = .orange
    mixed.configuration.appearance.indeterminateImage = UIImage(systemName: "minus.circle.fill", withConfiguration: config)

    box.addArrangedSubview(FKSelectionExampleSupport.embedControl(checked))
    box.addArrangedSubview(FKSelectionExampleSupport.embedControl(mixed))
    contentStack.addArrangedSubview(box)
  }
}
