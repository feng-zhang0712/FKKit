import UIKit
import FKUIKit

final class FKActionSheetExampleSymbolsAndStatesViewController: FKActionSheetExampleBaseViewController {
  private weak var liveSheet: FKActionSheet?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Symbols & States"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 8
    body.addArrangedSubview(FKActionSheetExampleUI.button("Symbols + subtitles") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentSymbolsAndSubtitles(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Disabled + loading") { [weak self] in
      guard let self else { return }
      self.liveSheet = FKActionSheetExamplePlaybook.presentDisabledAndLoading(from: self)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Clear loading state") { [weak self] in
      guard let self, let sheet = self.liveSheet else {
        FKActionSheetExamplePlaybook.log("No sheet — present disabled/loading sheet first")
        return
      }
      var share = FKActionSheetAction(title: "Share", symbolName: "square.and.arrow.up")
      share.isLoading = false
      share.isEnabled = true
      sheet.updateAction(share)
      FKActionSheetExamplePlaybook.log("updateAction cleared loading")
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Stay-open row") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentStayOpenAction(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Toggle row") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentToggleRows(from: $0) }
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Row content",
        description: "SF Symbol actions, subtitles, disabled/loading guards, stay-open rows, and FKActionSheetAction.toggle.",
        body: body
      )
    )
    addClearLogButton()
  }
}
