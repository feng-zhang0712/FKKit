import UIKit
import FKUIKit

final class FKActionSheetExampleSymbolsAndStatesViewController: FKActionSheetExampleBaseViewController {
  private weak var liveHandle: FKActionSheetHandle?

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
      self.liveHandle = FKActionSheetExamplePlaybook.presentDisabledAndLoading(from: self)
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Clear loading state") { [weak self] in
      guard let self, let handle = self.liveHandle else {
        FKActionSheetExamplePlaybook.log("No handle — present disabled/loading sheet first")
        return
      }
      var share = FKActionSheetAction(title: "Share", symbolName: "square.and.arrow.up")
      share.isLoading = false
      share.isEnabled = true
      handle.updateAction(share)
      FKActionSheetExamplePlaybook.log("updateAction cleared loading")
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Stay-open row") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentStayOpenAction(from: $0) }
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Row content",
        description: "SF Symbol actions, subtitles, disabled/loading guards, and per-row dismissesSheetWhenSelected.",
        body: body
      )
    )
    addClearLogButton()
  }
}
