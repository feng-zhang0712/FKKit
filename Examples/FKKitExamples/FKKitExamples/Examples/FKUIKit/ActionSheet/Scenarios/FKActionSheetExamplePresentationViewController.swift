import UIKit
import FKUIKit

final class FKActionSheetExamplePresentationViewController: FKActionSheetExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presentation"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 12
    body.addArrangedSubview(FKActionSheetExampleUI.button("Swipe + backdrop dismiss") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentSwipeAndBackdropOptions(from: $0) }
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Presentation tuning",
        description: "Opt in to swipe-to-dismiss and configure backdrop/tap behavior via FKActionSheetPresentationConfiguration.",
        body: body
      )
    )
    addClearLogButton()
  }
}
