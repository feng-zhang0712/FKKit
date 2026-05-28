import UIKit
import FKUIKit

/// Presents an anchor popup attached to the physical top edge of the screen.
///
/// Key highlights:
/// - Uses a rect provider at `y = 0` in window coordinates (not the safe-area inset).
/// - Hosts in the key window so the attachment line tracks the true screen top during rotation.
final class AnchorScreenTopEdgeExampleViewController: FKSheetPresentationExamplePageViewController {
  private var activePresentation: FKSheetPresentationController?

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Screen Top Edge Anchor",
      subtitle: "Popup expands downward from the top of the screen.",
      notes: "Rect-based anchors are useful when there is no dedicated source view (status-bar trays, global banners)."
    )

    addView(
      FKExampleControls.infoLabel(
        text: "The anchor line is resolved at the window's top edge (`y = 0`), so the panel visually originates from the screen top."
      )
    )

    addPrimaryButton(title: "Present from screen top") { [weak self] in
      self?.togglePresentation()
    }
  }

  private func togglePresentation() {
    if let activePresentation {
      activePresentation.dismiss(animated: true) { [weak self] in
        self?.activePresentation = nil
      }
      return
    }

    guard let window = view.window ?? UIApplication.shared.connectedScenes
      .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
      .first
    else {
      return
    }

    let anchor = FKAnchor(
      edge: .bottom,
      direction: .down,
      alignment: .fill,
      widthPolicy: .matchContainer,
      offset: 0,
      rectProvider: { [weak window] in
        guard let window else { return nil }
        let bounds = window.bounds
        return CGRect(x: 0, y: 0, width: bounds.width, height: 0)
      }
    )
    let anchorConfig = FKAnchorConfiguration(
      anchor: anchor,
      hostStrategy: .inWindowLevel,
      zOrderPolicy: .normal,
      maskCoveragePolicy: .fullScreen
    )

    var configuration = FKSheetPresentationConfiguration()
    configuration.layout = .anchor(anchorConfig)
    configuration.safeAreaPolicy = .contentRespectsSafeArea
    configuration.dismissBehavior = .init(allowsTapOutside: true, allowsSwipe: true, allowsBackdropTap: true)
    configuration.backdropStyle = .dim(color: .black, alpha: 0.25)
    configuration.cornerRadius = 0
    configuration.shadow = .none

    let content = FKExampleLabelContentViewController(text: "Screen top edge anchor popup")
    content.preferredContentSize = .init(width: 0, height: 240)

    activePresentation = FKSheetPresentationController.present(
      contentController: content,
      from: self,
      configuration: configuration,
      handlers: .init(didDismiss: { [weak self] in
        self?.activePresentation = nil
      })
    )
  }
}
