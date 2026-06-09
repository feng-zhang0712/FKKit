import UIKit
import FKUIKit

final class FKAlertExampleValidationFailureViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Validation Failure"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKAlertExampleUI.button("Show validation alert") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.validationPromptContent(),
        configuration: FKAlertPresets.textPrompt(),
        label: "validation"
      )
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "Inline FKTextField errors",
        description: "Invalid input shows FKTextField error UI and keeps the alert open. Return key runs the same validation path as the primary button.",
        body: body
      )
    )
    addClearLogButton()
  }
}
