import UIKit
import FKUIKit

final class FKActionSheetExampleCustomContentViewController: FKActionSheetExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Custom Content"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKActionSheetExampleUI.button("Custom header + row") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCustomHeaderAndRow(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Non-selectable banner") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentNonSelectableCustomRow(from: $0) }
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Phase 2 custom content",
        description: "FKActionSheetCustomHeader, FKActionSheetAction.custom with metadata, and isSelectable = false rows.",
        body: body
      )
    )
    addClearLogButton()
  }
}
