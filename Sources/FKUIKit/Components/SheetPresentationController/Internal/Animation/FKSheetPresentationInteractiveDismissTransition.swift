import UIKit

/// Drives swipe-to-dismiss completion with UIKit's interactive transition pipeline.
@MainActor
final class FKSheetPresentationInteractiveDismissTransition: UIPercentDrivenInteractiveTransition {
  /// Whether the next dismissal should use this interactor.
  private(set) var isArmed = false
  /// Fraction complete when the finger lifts (0...1).
  private(set) var completionFraction: CGFloat = 0
  /// Vertical pan velocity captured at dismiss decision time.
  private(set) var dismissalVelocityY: CGFloat = 0

  /// Arms the interactor before calling `dismiss(animated:)`.
  func arm(completionFraction: CGFloat, dismissalVelocityY: CGFloat) {
    isArmed = true
    self.completionFraction = min(max(completionFraction, 0), 1)
    self.dismissalVelocityY = dismissalVelocityY
  }

  /// Clears arm state after the transition ends.
  func reset() {
    isArmed = false
    completionFraction = 0
    dismissalVelocityY = 0
  }

  override func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
    super.startInteractiveTransition(transitionContext)
    update(completionFraction)
    finish()
  }
}
