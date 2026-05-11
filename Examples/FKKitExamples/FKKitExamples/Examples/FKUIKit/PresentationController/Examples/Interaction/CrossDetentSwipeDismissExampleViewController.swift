import UIKit
import FKUIKit

/// Demonstrates ``FKPresentationConfiguration/SheetConfiguration/crossDetentSwipeDismissPolicy``.
///
/// Try this flow: present at the **taller** detent, drag to shrink through the smaller detent, then keep dragging in the dismiss direction and release.
/// - **System aligned** (default): dismissal can finish on that same release when thresholds are met.
/// - **Strict (legacy)**: the first release usually snaps to the smallest detent only; you typically need a second pan to dismiss.
final class CrossDetentSwipeDismissExampleViewController: FKPresentationExamplePageViewController {
  private var policySegmentIndex = 0
  private var edgeSegmentIndex = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    setHeader(
      title: "Cross-detent swipe dismiss",
      subtitle: "`sheet.crossDetentSwipeDismissPolicy` — system-like vs strict-at-pan-start.",
      notes: "Sheet opens on the taller detent. Shrink to the smallest detent, keep moving in the dismiss direction, then release to feel the difference."
    )

    addView(
      FKExampleControls.segmented(
        title: "Policy",
        items: ["System aligned", "Strict (legacy)"],
        selectedIndex: policySegmentIndex
      ) { [weak self] index in
        self?.policySegmentIndex = index
      }
    )

    addView(
      FKExampleControls.segmented(
        title: "Sheet",
        items: ["Bottom", "Top"],
        selectedIndex: edgeSegmentIndex
      ) { [weak self] index in
        self?.edgeSegmentIndex = index
      }
    )

    addView(
      FKExampleControls.infoLabel(
        text:
          "System aligned: once the frame reaches the smallest detent, extra drag can dismiss in one gesture.\nStrict: swipe dismiss uses only the detent index from when the pan began — cross-detent dismiss in one lift is disabled."
      )
    )

    addPrimaryButton(title: "Present") { [weak self] in
      self?.presentDemoSheet()
    }
  }

  private func presentDemoSheet() {
    let policy: FKPresentationConfiguration.SheetConfiguration.CrossDetentSwipeDismissPolicy =
      policySegmentIndex == 0 ? .systemAligned : .strictSmallestDetentAtPanStart

    var configuration: FKPresentationConfiguration
    if edgeSegmentIndex == 0 {
      configuration = FKPresentationExampleHelpers.bottomSheetConfiguration()
    } else {
      configuration = FKPresentationExampleHelpers.topSheetConfiguration()
    }

    configuration.sheet.detents = [.fixed(260), .large]
    configuration.sheet.initialSelectedDetentIndex = 1
    configuration.sheet.crossDetentSwipeDismissPolicy = policy
    configuration.dismissBehavior.allowsSwipe = true

    let policyTitle = policySegmentIndex == 0 ? "System aligned" : "Strict (legacy)"
    let edgeTitle = edgeSegmentIndex == 0 ? "Bottom" : "Top"
    let dragHint =
      edgeSegmentIndex == 0
        ? "Shrink to the short detent, keep dragging downward, then release."
        : "Shrink to the short detent, keep dragging upward, then release."
    let body = "Policy: \(policyTitle). Edge: \(edgeTitle) sheet.\n\n\(dragHint)"
    let content = FKExampleLabelContentViewController(text: body)
    content.title = "Cross-detent dismiss"

    _ = FKPresentationController.present(
      contentController: content,
      from: self,
      configuration: configuration,
      animated: true,
      completion: nil
    )
  }
}
