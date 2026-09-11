import UIKit

/// Applies and restores scroll-view content / indicator insets for keyboard avoidance.
@MainActor
final class FKKeyboardScrollInsetApplier {
  private var originalInsets: (
    content: UIEdgeInsets,
    verticalIndicator: UIEdgeInsets,
    horizontalIndicator: UIEdgeInsets
  )?

  /// Original `contentInset.top` captured before keyboard adjustments, if any.
  var capturedContentTop: CGFloat? { originalInsets?.content.top }

  /// Original `contentInset.bottom` captured before keyboard adjustments, if any.
  var capturedContentBottom: CGFloat? { originalInsets?.content.bottom }

  /// Adds keyboard `bottomInset` and optional `extraTopInset` (IQ-style short-content pull-down)
  /// on top of the originally captured insets.
  func apply(bottomInset: CGFloat, extraTopInset: CGFloat = 0, to scroll: UIScrollView) {
    if originalInsets == nil {
      originalInsets = (
        scroll.contentInset,
        scroll.verticalScrollIndicatorInsets,
        scroll.horizontalScrollIndicatorInsets
      )
    }
    let base = originalInsets ?? (
      scroll.contentInset,
      scroll.verticalScrollIndicatorInsets,
      scroll.horizontalScrollIndicatorInsets
    )
    scroll.contentInset = UIEdgeInsets(
      top: base.content.top + max(0, extraTopInset),
      left: base.content.left,
      bottom: base.content.bottom + max(0, bottomInset),
      right: base.content.right
    )
    var verticalIndicator = base.verticalIndicator
    verticalIndicator.top = base.verticalIndicator.top + max(0, extraTopInset)
    verticalIndicator.bottom = base.verticalIndicator.bottom + max(0, bottomInset)
    scroll.verticalScrollIndicatorInsets = verticalIndicator
    scroll.horizontalScrollIndicatorInsets = base.horizontalIndicator
  }

  /// Restores insets captured before the first apply, if any.
  ///
  /// Also repairs `contentOffset`: removing IQ-style extra top inset without a matching
  /// offset correction leaves a permanent blank band above the content (UIScrollView does
  /// not clamp programmatically-set offsets when insets shrink).
  func restore(to scroll: UIScrollView?) {
    guard let scroll, let originalInsets else { return }
    let topDelta = scroll.contentInset.top - originalInsets.content.top
    scroll.contentInset = originalInsets.content
    scroll.verticalScrollIndicatorInsets = originalInsets.verticalIndicator
    scroll.horizontalScrollIndicatorInsets = originalInsets.horizontalIndicator
    self.originalInsets = nil

    // Keep content visually stable when top inset shrinks, then clamp to a legal range
    // (bottom inset removal can leave offset past the new maximum).
    var offset = scroll.contentOffset
    offset.y += topDelta
    let inset = scroll.adjustedContentInset
    let minY = -inset.top
    let maxY = max(minY, scroll.contentSize.height + inset.bottom - scroll.bounds.height)
    offset.y = min(max(offset.y, minY), maxY)
    if abs(offset.y - scroll.contentOffset.y) > 0.5
      || abs(offset.x - scroll.contentOffset.x) > 0.5
    {
      scroll.contentOffset = offset
    }
  }

  /// Drops stored originals without mutating a scroll view (host already released).
  func reset() {
    originalInsets = nil
  }
}
