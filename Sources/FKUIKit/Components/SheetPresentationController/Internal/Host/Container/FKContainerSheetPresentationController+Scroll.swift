import UIKit

@MainActor
extension FKContainerSheetPresentationController {
  // MARK: - Scroll Resolution

  /// Depth-first lookup for the first scroll view in presented content.
  func findPrimaryScrollView(in root: UIView?) -> UIScrollView? {
    FKSheetScrollTracking.findPrimaryScrollView(in: root)
  }

  /// Resolves keyboard inset target: explicit configuration first, fallback to first discovered scroll view.
  func resolveKeyboardTargetScrollView() -> UIScrollView? {
    if let explicit = configuration.keyboardAvoidance.targetScrollView?.object {
      return explicit
    }
    return findPrimaryScrollView(in: presentedViewController.view)
  }

  /// Resolves the sheet pan-handoff scroll view based on selected strategy.
  func resolvedTrackedScrollView() -> UIScrollView? {
    FKSheetScrollTracking.resolvedTrackedScrollView(
      strategy: configuration.sheet.scrollTrackingStrategy,
      in: presentedViewController.view
    )
  }
}
