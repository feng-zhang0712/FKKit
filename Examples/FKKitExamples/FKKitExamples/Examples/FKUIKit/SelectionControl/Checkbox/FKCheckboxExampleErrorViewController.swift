import FKUIKit
import UIKit

/// checkbox.error — showsError.
final class FKCheckboxExampleErrorViewController: FKSelectionExampleScrollViewController {
  private let checkbox = FKCheckbox(title: "I accept the terms", checkState: .unchecked)

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Error state"

    let box = FKSelectionExampleSupport.sectionContainer(title: "Validation")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("showsError draws an error border on unchecked / mixed indicators. Clear it after the user corrects the value."))

    checkbox.onStateChanged = { [weak self] state in
      if state == .checked { self?.checkbox.showsError = false }
    }
    box.addArrangedSubview(FKSelectionExampleSupport.embedControl(checkbox))
    box.addArrangedSubview(FKSelectionExampleSupport.makeButton(title: "Validate") { [weak self] in
      guard let self else { return }
      let ok = self.checkbox.checkState == .checked
      self.checkbox.showsError = !ok
    })
    contentStack.addArrangedSubview(box)
  }
}
