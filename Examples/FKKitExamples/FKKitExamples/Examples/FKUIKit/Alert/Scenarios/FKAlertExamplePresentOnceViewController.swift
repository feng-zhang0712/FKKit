import UIKit
import FKUIKit

final class FKAlertExamplePresentOnceViewController: FKAlertExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Present Once"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKAlertExampleUI.button("Present once (same id)") { [weak self] in
      self?.presentOnce(
        FKAlertExamplePlaybook.syncErrorContent(),
        label: "presentOnce attempt"
      )
    })
    body.addArrangedSubview(FKAlertExampleUI.button("Present once (different id)") { [weak self] in
      self?.presentOnce(
        FKAlertExamplePlaybook.syncErrorContent(id: "network-sync-error-\(UUID().uuidString.prefix(4))"),
        label: "presentOnce unique id"
      )
    })

    contentStack.addArrangedSubview(
      FKAlertExampleUI.section(
        title: "BusinessKit-compatible dedup",
        description: "Tap the first button twice quickly. The second call returns nil while the first alert is visible. Matches FKBusinessAlertManager.presentOnce semantics.",
        body: body
      )
    )
    addClearLogButton()
  }
}
