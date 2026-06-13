import FKCoreKit
import UIKit
import FKUIKit

final class FKAlertExampleAppearanceViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Appearance & Layout"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8

    body.addArrangedSubview(FKAlertExampleUI.button("Warning icon tint") { [weak self] in
      var content = FKAlertExamplePlaybook.checkboxGatedDeleteContent()
      content.dangerousAction = nil
      self?.presentAlert(content, label: "warning icon")
    })

    body.addArrangedSubview(FKAlertExampleUI.button("Attributed message") { [weak self] in
      let attributed = FKAlertExamplePlaybook.attributedMessageContent()
      let content = FKAlertContent(
        title: "Refund available",
        attributedMessage: FKAlertContent.archiveAttributedMessage(attributed),
        actions: [
          FKAlertAction(title: "Request refund", style: .default),
          FKAlertAction(title: "Not now", style: .cancel),
        ]
      )
      self?.presentAlert(content, label: "attributed")
    })

    body.addArrangedSubview(FKAlertExampleUI.button("Horizontal button pair") { [weak self] in
      var configuration = FKAlertConfiguration()
      configuration.buttonLayout = .horizontalPair
      self?.presentAlert(
        FKAlertExamplePlaybook.horizontalPairContent(),
        configuration: configuration,
        label: "horizontal pair"
      )
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "Visual variants",
        description: "FKAlertIcon supports SF Symbols and asset names. horizontalPair lays out exactly two non-destructive primary actions side by side.",
        body: body
      )
    )
    addClearLogButton()
  }
}
