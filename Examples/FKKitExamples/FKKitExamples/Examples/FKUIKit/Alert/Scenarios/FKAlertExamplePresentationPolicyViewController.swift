import UIKit
import FKUIKit

final class FKAlertExamplePresentationPolicyViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presentation Policy"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKAlertExampleUI.button("Backdrop tap dismiss (informational)") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.informationalContent(),
        configuration: FKAlertPresets.informational(),
        label: "backdrop allowed"
      )
    })

    body.addArrangedSubview(FKAlertExampleUI.button("Backdrop blocked (destructive preset)") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.destructiveDeleteContent(),
        configuration: FKAlertPresets.destructiveConfirm(),
        label: "backdrop blocked"
      )
    })

    body.addArrangedSubview(FKAlertExampleUI.button("Swipe dismiss enabled (opt-in)") { [weak self] in
      var configuration = FKAlertPresets.informational()
      configuration.presentation.allowsSwipeToDismiss = true
      self?.presentAlert(
        FKAlertExamplePlaybook.informationalContent(),
        configuration: configuration,
        label: "swipe enabled"
      )
    })

    body.addArrangedSubview(FKAlertExampleUI.button("Swipe dismiss disabled (text prompt)") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.renamePromptContent(initial: ""),
        configuration: FKAlertPresets.textPrompt(),
        label: "swipe disabled"
      )
    })

    body.addArrangedSubview(FKAlertExampleUI.button("Custom corner radius (24pt)") { [weak self] in
      var configuration = FKAlertPresets.informational()
      configuration.presentation.cornerRadius = 24
      self?.presentAlert(
        FKAlertExamplePlaybook.informationalContent(),
        configuration: configuration,
        label: "corner radius"
      )
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "Sheet integration",
        description: "Alerts use FKSheetPresentationController centerAlert defaults (~320pt width, fitted height). Informational preset uses backdrop tap only; swipe is off by default because center pans cannot start on buttons. Opt in via allowsSwipeToDismiss when needed.",
        body: body
      )
    )
    addClearLogButton()
  }
}
