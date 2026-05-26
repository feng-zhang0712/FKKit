import UIKit
import FKUIKit

final class FKActionSheetExamplePresentationViewController: FKActionSheetExampleBaseViewController {
  private lazy var popoverAnchorButton: UIButton = {
    FKActionSheetExampleUI.button("Present popover (anchored here)") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentPopover(from: self, anchor: popoverAnchorButton)
    }
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presentation"

    let body = UIStackView()
    body.axis = .vertical
    body.spacing = 12
    body.addArrangedSubview(FKActionSheetExampleUI.button("Bottom + backdrop dismiss") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentSwipeAndBackdropOptions(from: $0) }
    })
    body.addArrangedSubview(FKActionSheetExampleUI.button("Centered card") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentCentered(from: $0) }
    })
    body.addArrangedSubview(popoverAnchorButton)

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Presentation styles",
        description: "FKActionSheetPresentationStyle supports .bottom (default), .centered (dimmed full-screen card), and .popover (supply FKActionSheetPresentationHostContext popover anchor).",
        body: body
      )
    )
    addClearLogButton()
  }
}
