import UIKit
import FKUIKit

final class FKAlertExampleCheckboxGatedDeleteViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Checkbox-Gated Delete"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKAlertExampleUI.button("Show gated destructive alert") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.checkboxGatedDeleteContent(),
        configuration: FKAlertPresets.destructiveConfirm(),
        label: "checkbox gated"
      )
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "Dangerous action options",
        description: "FKAlertDangerousActionOptions.requiresConfirmationCheckbox disables the destructive button until the confirmation switch is on. Backdrop and swipe dismiss are also blocked.",
        body: body
      )
    )
    addClearLogButton()
  }
}
