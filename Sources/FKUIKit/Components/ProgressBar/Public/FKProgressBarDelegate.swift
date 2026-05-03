import UIKit

/// Optional hooks for analytics, chained animations, or custom UI around determinate changes.
@MainActor
public protocol FKProgressBarDelegate: AnyObject {
  /// Called immediately before a determinate progress animation is applied (including implicit layout animations).
  func progressBar(_ progressBar: FKProgressBar, willAnimateProgress from: CGFloat, to: CGFloat, duration: TimeInterval)

  /// Called on the main queue after the determinate animation completes or is cancelled to the final value.
  func progressBar(_ progressBar: FKProgressBar, didAnimateProgressTo value: CGFloat)

  /// Indeterminate mode toggled.
  func progressBar(_ progressBar: FKProgressBar, didChangeIndeterminate isIndeterminate: Bool)

  /// Buffer progress changed (same semantics as primary progress for animation).
  func progressBar(_ progressBar: FKProgressBar, didUpdateBufferProgress value: CGFloat)
}

public extension FKProgressBarDelegate {
  func progressBar(_ progressBar: FKProgressBar, willAnimateProgress from: CGFloat, to: CGFloat, duration: TimeInterval) {}

  func progressBar(_ progressBar: FKProgressBar, didAnimateProgressTo value: CGFloat) {}

  func progressBar(_ progressBar: FKProgressBar, didChangeIndeterminate isIndeterminate: Bool) {}

  func progressBar(_ progressBar: FKProgressBar, didUpdateBufferProgress value: CGFloat) {}
}
