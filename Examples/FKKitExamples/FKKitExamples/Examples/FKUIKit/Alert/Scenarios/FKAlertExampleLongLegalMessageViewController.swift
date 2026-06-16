import UIKit
import FKUIKit

final class FKAlertExampleLongLegalMessageViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Long Legal Message"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKAlertExampleUI.button("Show long message alert") { [weak self] in
      self?.presentAlert(
        FKAlertExamplePlaybook.longLegalContent(),
        configuration: FKAlertPresets.informational(),
        label: "long message"
      )
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "Scrollable body",
        description: "Short alerts grow to fit their content. When the fitted max height or screen bounds are exceeded, the alert body scrolls as a single region while buttons stay pinned. Swipe-to-dismiss only engages when the body scroll view is at the top.",
        body: body
      )
    )
    addClearLogButton()
  }
}
