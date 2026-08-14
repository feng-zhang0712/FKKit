import FKUIKit
import UIKit

/// checkbox.readOnly.
final class FKCheckboxExampleReadOnlyViewController: FKSelectionExampleScrollViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Read-only"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Display only")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("interactionMode = .readOnly ignores toggle taps. Links can still fire when using attributed titles."))

    let checked = FKCheckbox(title: "Feature enabled (read-only)", checkState: .checked)
    checked.interactionMode = .readOnly
    let mixed = FKCheckbox(title: "Partial selection (read-only)", checkState: .indeterminate)
    mixed.interactionMode = .readOnly

    box.addArrangedSubview(FKSelectionExampleSupport.embedControl(checked))
    box.addArrangedSubview(FKSelectionExampleSupport.embedControl(mixed))
    contentStack.addArrangedSubview(box)
  }
}
