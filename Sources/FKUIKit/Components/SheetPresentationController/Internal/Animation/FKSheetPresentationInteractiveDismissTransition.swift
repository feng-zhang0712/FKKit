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
    // Scrub to the finger-lift fraction so remaining spring motion starts mid-flight rather than
    // replaying the full dismiss from 0 when the sheet is already partially off-screen.
    let fraction = min(max(completionFraction, 0), 0.99)
    update(fraction)
    // Faster finish when the user already dragged far; keep a floor so motion never looks abrupt.
    completionSpeed = max(0.65, 1.15 - fraction * 0.45)
    finish()
  }
}
