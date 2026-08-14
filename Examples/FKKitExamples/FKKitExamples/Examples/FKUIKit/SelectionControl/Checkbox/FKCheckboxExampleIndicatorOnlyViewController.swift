import FKUIKit
import UIKit

/// checkbox.indicatorOnly.
final class FKCheckboxExampleIndicatorOnlyViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Indicator only"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Custom cell pattern")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Use FKCheckboxPresets.indicatorOnly() when the cell owns the title layout."))

    let row = UIStackView()
    row.axis = .horizontal
    row.alignment = .center
    row.spacing = 12

    let checkbox = FKCheckbox(configuration: FKCheckboxPresets.indicatorOnly(), content: .init())
    checkbox.setCheckState(.checked, animated: false, sendActions: false)

    let labels = UIStackView()
    labels.axis = .vertical
    labels.spacing = 2
    let title = UILabel()
    title.text = "Allow notifications"
    title.font = .preferredFont(forTextStyle: .body)
    let subtitle = UILabel()
    subtitle.text = "Title provided by the host cell"
    subtitle.font = .preferredFont(forTextStyle: .footnote)
    subtitle.textColor = .secondaryLabel
    labels.addArrangedSubview(title)
    labels.addArrangedSubview(subtitle)

    row.addArrangedSubview(checkbox)
    row.addArrangedSubview(labels)
    box.addArrangedSubview(row)
    contentStack.addArrangedSubview(box)
  }
}
