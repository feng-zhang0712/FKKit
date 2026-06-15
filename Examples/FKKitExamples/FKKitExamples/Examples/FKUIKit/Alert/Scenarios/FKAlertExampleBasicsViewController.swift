import UIKit
import FKUIKit

final class FKAlertExampleBasicsViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Basics & Helpers"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKAlertExampleUI.button("Informational (default OK)") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.informationalContent(),
        configuration: FKAlertPresets.informational(),
        label: "informational"
      )
    })
    body.addArrangedSubview(FKAlertExampleUI.button("FKAlert.confirm (non-destructive)") { [weak self] in
      guard let self else { return }
      Task { @MainActor in
        let confirmed = await FKAlert.confirm(
          title: "Enable notifications?",
          message: "Stay informed about messages and updates.",
          confirmTitle: "Enable",
          from: self
        )
        FKAlertExampleLog.log("confirm → \(confirmed)")
      }
    })
    body.addArrangedSubview(FKAlertExampleUI.button("FKAlert.prompt") { [weak self] in
      guard let self else { return }
      Task { @MainActor in
        let name = await FKAlert.prompt(
          title: "New folder",
          message: nil,
          placeholder: "Folder name",
          confirmTitle: "Create",
          from: self,
          configuration: FKAlertPresets.textPrompt()
        )
        FKAlertExampleLog.log("prompt → \(name ?? "nil")")
      }
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "Presenter entry points",
        description: "Use FKAlertPresenter.shared.present for full control, or FKAlert.confirm / FKAlert.prompt for common flows. Empty actions receive a localized OK button.",
        body: body
      )
    )
    addClearLogButton()
  }
}
