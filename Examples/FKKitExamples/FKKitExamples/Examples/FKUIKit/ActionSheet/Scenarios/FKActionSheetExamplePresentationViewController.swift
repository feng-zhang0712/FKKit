import UIKit
import FKUIKit

/// Bottom sheet, popover anchors, and window-scene presentation.
final class FKActionSheetExamplePresentationViewController: FKActionSheetExampleBaseViewController {
  private lazy var popoverSourceButton: UIButton = {
    FKActionSheetExampleUI.button("Popover (source view)") { [weak self] in
      guard let self else { return }
      FKActionSheetExamplePlaybook.presentPopover(from: self, anchor: popoverSourceButton)
    }
  }()

  private lazy var popoverBarButtonItem: UIBarButtonItem = {
    UIBarButtonItem(
      title: "Bar popover",
      primaryAction: UIAction { [weak self] _ in
        guard let self else { return }
        FKActionSheetExamplePlaybook.presentPopover(from: self, barButtonItem: popoverBarButtonItem)
      }
    )
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Presentation"
    navigationItem.rightBarButtonItem = popoverBarButtonItem

    let bottom = UIStackView()
    bottom.axis = .vertical
    bottom.spacing = 8
    bottom.addArrangedSubview(FKActionSheetExampleUI.button("Backdrop dismiss") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentBackdropDismiss(from: $0) }
    })
    bottom.addArrangedSubview(FKActionSheetExampleUI.button("Backdrop dismiss disabled") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentBackdropDismissDisabled(from: $0) }
    })
    bottom.addArrangedSubview(FKActionSheetExampleUI.button("Panel height cap (280pt)") { [weak self] in
      self.map { FKActionSheetExamplePlaybook.presentBottomSheetWithHeightCap(from: $0) }
    })

    let popover = UIStackView()
    popover.axis = .vertical
    popover.spacing = 8
    popover.addArrangedSubview(popoverSourceButton)

    let scene = UIStackView()
    scene.axis = .vertical
    scene.spacing = 8
    scene.addArrangedSubview(FKActionSheetExampleUI.button("Present via window scene") { [weak self] in
      guard let self, let windowScene = self.view.window?.windowScene else {
        FKActionSheetExamplePlaybook.log("No window scene — open from a window first")
        return
      }
      FKActionSheetExamplePlaybook.presentFromWindowScene(windowScene)
    })

    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Bottom sheet (.bottom)",
        description: "Default FKActionSheetPresentationConfiguration. Slide-up transition with optional backdrop tap dismiss.",
        body: bottom
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Popover (.popover)",
        description: "Requires present(from:anchoredTo:). Use a source view or UIBarButtonItem; adapt on compact width.",
        body: popover
      )
    )
    contentStack.addArrangedSubview(
      FKActionSheetExampleUI.section(
        title: "Window scene",
        description: "present(in:) resolves the topmost presenter in the scene — useful for deep links or scene-based apps.",
        body: scene
      )
    )
    addClearLogButton()
  }
}
