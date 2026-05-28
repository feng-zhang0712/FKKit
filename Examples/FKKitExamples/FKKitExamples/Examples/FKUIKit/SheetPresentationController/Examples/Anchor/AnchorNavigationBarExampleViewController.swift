import UIKit
import FKUIKit

/// Presents an anchor popup attached to the navigation bar bottom edge.
///
/// Key highlights:
/// - Uses the system navigation bar as the geometry source (typical menu / filter dropdown pattern).
/// - Keeps the bar above the overlay via `keepAnchorAbovePresentation` and a below-anchor mask.
final class AnchorNavigationBarExampleViewController: FKSheetPresentationExamplePageViewController {
  private var activePresentation: FKSheetPresentationController?

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Navigation Bar Anchor",
      subtitle: "Popup expands downward from the navigation bar bottom edge.",
      notes: "Use this pattern for title-bar menus, filters, and account pickers. Tap Present again (or the backdrop) to dismiss."
    )

    addView(
      FKExampleControls.infoLabel(
        text: "This screen is pushed inside a navigation stack so the system navigation bar is available as the anchor source."
      )
    )

    addPrimaryButton(title: "Present from navigation bar") { [weak self] in
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

    guard let navigationBar = navigationController?.navigationBar else {
      return
    }

    let anchor = FKAnchor(
      sourceView: navigationBar,
      edge: .bottom,
      direction: .down,
      alignment: .fill,
      widthPolicy: .matchContainer,
      offset: 0
    )
    let anchorConfig = FKAnchorConfiguration(
      anchor: anchor,
      hostStrategy: .inSameSuperviewBelowAnchor,
      zOrderPolicy: .keepAnchorAbovePresentation,
      maskCoveragePolicy: .belowAnchorOnly
    )

    var configuration = FKSheetPresentationConfiguration()
    configuration.layout = .anchor(anchorConfig)
    configuration.dismissBehavior = .init(allowsTapOutside: true, allowsSwipe: true, allowsBackdropTap: true)
    configuration.backdropStyle = .dim(color: .black, alpha: 0.25)
    configuration.cornerRadius = 12
    configuration.shadow = .custom(color: .black, opacity: 0.18, radius: 16, offset: CGSize(width: 0, height: 8))

    let content = FKExampleLabelContentViewController(text: "Navigation bar anchor popup")
    content.preferredContentSize = .init(width: 0, height: 280)

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
