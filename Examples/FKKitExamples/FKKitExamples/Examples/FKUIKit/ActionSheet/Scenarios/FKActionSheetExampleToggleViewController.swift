import UIKit
import FKUIKit

final class FKActionSheetExampleToggleViewController: FKActionSheetExampleBaseViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Toggle Rows"

    let body = FKActionSheetExampleUI.button("Toggle sheet") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentToggleRows(from: $0) }
    }

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Switch rows",
        description: "FKActionSheetAction.toggle keeps the sheet open and streams toggleValueChanged callbacks to the event log.",
        body: body
      )
    )
    addClearLogButton()
  }
}
