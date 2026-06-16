import UIKit
import FKUIKit

final class FKAlertExampleTextFieldRenameViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Text Field Rename"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKAlertExampleUI.button("Rename via FKAlertPresenter") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.renamePromptContent(),
        configuration: FKAlertPresets.textPrompt(),
        label: "rename"
      )
    })
    body.addArrangedSubview(FKAlertExampleUI.button("Rename via FKAlert.prompt") { [weak self] in
      guard let self else { return }
      Task { @MainActor in
        let value = await FKAlert.prompt(
          title: "Rename playlist",
          message: "Visible to collaborators immediately.",
          placeholder: "Playlist name",
          confirmTitle: "Save",
          from: self,
          configuration: FKAlertPresets.textPrompt()
        )
        FKAlertExampleLog.log("prompt rename → \(value ?? "nil")")
      }
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "Single-line FKTextField",
        description: "Text field alerts auto-focus after presentation. FKAlertResult.action includes trimmed text when Save is tapped.",
        body: body
      )
    )
    addClearLogButton()
  }
}
