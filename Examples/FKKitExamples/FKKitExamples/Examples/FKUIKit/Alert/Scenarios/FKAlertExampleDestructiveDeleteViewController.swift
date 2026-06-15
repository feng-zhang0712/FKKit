import UIKit
import FKUIKit

final class FKAlertExampleDestructiveDeleteViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Destructive Delete"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKAlertExampleUI.button("Presenter + destructiveConfirm preset") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.destructiveDeleteContent(),
        configuration: FKAlertPresets.destructiveConfirm(),
        label: "destructive"
      )
    })
    body.addArrangedSubview(FKAlertExampleUI.button("FKAlert.confirm (isDestructive: true)") { [weak self] in
      guard let self else { return }
      Task { @MainActor in
        let confirmed = await FKAlert.confirm(
          title: "Delete draft?",
          message: "This draft cannot be recovered.",
          confirmTitle: "Delete",
          isDestructive: true,
          from: self,
          configuration: FKAlertPresets.destructiveConfirm()
        )
        FKAlertExampleLog.log("destructive confirm → \(confirmed)")
      }
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "Destructive styling",
        description: "Destructive actions use FKButton destructive styling, appear above cancel, and the destructiveConfirm preset disables backdrop and swipe dismiss.",
        body: body
      )
    )
    addClearLogButton()
  }
}
