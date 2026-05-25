import UIKit
import FKUIKit

final class FKActionSheetExampleLiveUpdatesViewController: FKActionSheetExampleBaseViewController {
  private weak var liveHandle: FKActionSheetHandle?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Live Updates"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKActionSheetExampleUI.button("Present for reload") { [weak self] in
      guard let self else { return }
      self.liveHandle = FKActionSheetExamplePlaybook.presentForLiveReload(from: self)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Reload with new title") { [weak self] in
      guard let self, let handle = self.liveHandle else {
        FKActionSheetExamplePlaybook.log("No handle — present reload demo first")
        return
      }
      let updated = FKActionSheetConfiguration(
        header: .text(FKActionSheetHeader(title: "Reloaded", message: "Header and actions replaced.")),
        sections: [
          FKActionSheetSection(actions: [
            FKActionSheetAction(title: "New action") { FKActionSheetExamplePlaybook.log("New action") },
          ]),
        ],
        cancelAction: FKActionSheetExamplePlaybook.makeCancelAction()
      )
      handle.reload(configuration: updated)
      FKActionSheetExamplePlaybook.log("handle.reload applied")
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("updateAction loading") { [weak self] in
      guard let self, let handle = self.liveHandle else {
        FKActionSheetExamplePlaybook.log("No handle — present reload demo first")
        return
      }
      var share = FKActionSheetAction(title: "Sharing…", symbolName: "square.and.arrow.up")
      share.isLoading = true
      share.isEnabled = false
      handle.updateAction(share)
      FKActionSheetExamplePlaybook.log("handle.updateAction loading")
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("presentOnce (same id)") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentOnceDemo(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.row([
      FKActionSheetExampleUI.button("isPresenting") {
        FKActionSheetExamplePlaybook.log("isPresenting = \(FKActionSheet.isPresenting)")
      },
      FKActionSheetExampleUI.button("dismissActive") {
        FKActionSheet.dismissActive()
        FKActionSheetExamplePlaybook.log("dismissActive called")
      },
    ]))

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "FKActionSheetHandle",
        description: "Retain a handle to reload configuration, patch single rows, dedupe with presentOnce, and query global presentation state.",
        body: body
      )
    )
    addClearLogButton()
  }
}
