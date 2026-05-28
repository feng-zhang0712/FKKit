import UIKit

/// Supplies custom transition animators for presentation and dismissal.
@MainActor
public protocol FKSheetPresentationAnimatorProviding {
  /// Returns an animator used when content is being presented.
  func makePresentationAnimator() -> UIViewControllerAnimatedTransitioning
  /// Returns an animator used when content is being dismissed.
  func makeDismissalAnimator() -> UIViewControllerAnimatedTransitioning
}
