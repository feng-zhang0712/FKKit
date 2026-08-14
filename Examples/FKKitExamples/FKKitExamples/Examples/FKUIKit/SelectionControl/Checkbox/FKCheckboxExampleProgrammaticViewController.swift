import FKUIKit
import UIKit

/// checkbox.programmatic — setCheckState / toggle.
final class FKCheckboxExampleProgrammaticViewController: FKSelectionExampleScrollViewController {
  private let checkbox = FKCheckbox(title: "Programmatic target", checkState: .unchecked)
  private let (status, updateStatus) = FKSelectionExampleSupport.statusLabel(prefix: "State")

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Programmatic"

    let box = FKSelectionExampleSupport.sectionContainer(title: "API")
    box.addArrangedSubview(FKSelectionExampleSupport.caption("Drive the control with setCheckState and toggle without relying on user taps."))
    checkbox.onStateChanged = { [weak self] state in
      self?.updateStatus(String(describing: state))
    }
    updateStatus(String(describing: checkbox.checkState))
    box.addArrangedSubview(FKSelectionExampleSupport.embedControl(checkbox))
    box.addArrangedSubview(status)

    let actions = UIStackView()
    actions.axis = .vertical
    actions.spacing = 8
    actions.addArrangedSubview(FKSelectionExampleSupport.makeButton(title: "Toggle") { [weak self] in
      self?.checkbox.toggle(animated: true, sendActions: true)
    })
    actions.addArrangedSubview(FKSelectionExampleSupport.makeButton(title: "Set checked") { [weak self] in
      self?.checkbox.setCheckState(.checked, animated: true, sendActions: true)
    })
    actions.addArrangedSubview(FKSelectionExampleSupport.makeButton(title: "Set indeterminate") { [weak self] in
      self?.checkbox.setCheckState(.indeterminate, animated: true, sendActions: true)
    })
    actions.addArrangedSubview(FKSelectionExampleSupport.makeButton(title: "Clear") { [weak self] in
      self?.checkbox.setCheckState(.unchecked, animated: true, sendActions: true)
    })
    box.addArrangedSubview(actions)
    contentStack.addArrangedSubview(box)
  }
}
