import UIKit
import FKUIKit

/// Presents an anchor popup attached to the physical bottom edge of the screen.
///
/// Key highlights:
/// - Uses a rect provider at the window bottom (`y = bounds.maxY`).
/// - Panel expands upward, similar to a compact bottom-attached tray.
final class AnchorScreenBottomEdgeExampleViewController: FKSheetPresentationExamplePageViewController {
  private var activePresentation: FKSheetPresentationController?

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Screen Bottom Edge Anchor",
      subtitle: "Popup expands upward from the bottom of the screen.",
      notes: "Rect-based bottom anchors are useful for compact action trays that should hug the physical screen edge."
    )

    addView(
      FKExampleControls.infoLabel(
        text: "The anchor line is resolved at the window bottom edge, so the panel grows upward from the screen bottom."
      )
    )

    addPrimaryButton(title: "Present from screen bottom") { [weak self] in
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
      edge: .top,
      direction: .up,
      alignment: .fill,
      widthPolicy: .matchContainer,
      offset: 0,
      rectProvider: { [weak window] in
        guard let window else { return nil }
        let bounds = window.bounds
        return CGRect(x: 0, y: bounds.maxY, width: bounds.width, height: 0)
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

    let content = FKExampleLabelContentViewController(text: "Screen bottom edge anchor popup")
    content.preferredContentSize = .init(width: 0, height: 260)

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
