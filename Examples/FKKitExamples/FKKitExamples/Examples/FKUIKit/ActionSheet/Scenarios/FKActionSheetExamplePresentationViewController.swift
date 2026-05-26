import UIKit
import FKUIKit

final class FKActionSheetExamplePresentationViewController: FKActionSheetExampleBaseViewController {
  private lazy var popoverAnchorButton: UIButton = {
    FKActionSheetExampleUI.button("Popover (static API)") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentPopover(from: self, anchor: popoverAnchorButton)
    }
  }()

  private lazy var popoverInstanceAnchorButton: UIButton = {
    FKActionSheetExampleUI.button("Popover (instance API)") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentPopoverInstance(from: self, anchor: popoverInstanceAnchorButton)
    }
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presentation"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 12
    body.addArrangedSubview(FKActionSheetExampleUI.button("Bottom + backdrop dismiss") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentBackdropDismiss(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Backdrop dismiss disabled") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentBackdropDismissDisabled(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Centered card") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCentered(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Present via window scene") { [weak self] in
      guard let self, let scene = self.view.window?.windowScene else {
        FKActionSheetExamplePlaybook.log("No window scene — open from a window first")
        return
      }
      FKActionSheetExamplePlaybook.presentFromWindowScene(scene)
    })
    body.addArrangedSubview(popoverAnchorButton)
    body.addArrangedSubview(popoverInstanceAnchorButton)

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Presentation styles",
        description: "FKActionSheetPresentationStyle: .bottom (default), .centered (dimmed card), .popover (requires present(from:anchoredTo:) or static anchoredTo:). Window-scene presentation resolves the topmost presenter automatically.",
        body: body
      )
    )
    addClearLogButton()
  }
}
