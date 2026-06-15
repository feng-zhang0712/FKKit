import UIKit
import FKUIKit

final class FKAlertExampleAccessibilityViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Accessibility"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKAlertExampleUI.button("Present accessibility demo alert") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.accessibilityDemoContent(),
        configuration: FKAlertPresets.textPrompt(),
        label: "accessibility"
      )
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "VoiceOver behavior",
        description: "With VoiceOver enabled: title and message are announced on appear; focus moves to the text field when present, otherwise to the title; destructive buttons include an optional hint; the confirmation switch updates destructive enablement announcements in checkbox-gated flows (see Checkbox-gated delete).",
        body: body
      )
    )
    addClearLogButton()
  }
}
