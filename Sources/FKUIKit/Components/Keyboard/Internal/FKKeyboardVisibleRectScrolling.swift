import UIKit

/// Focus positioning inside a scroll view that accounts for keyboard-driven bottom insets.
///
/// System `scrollRectToVisible` ignores keyboard-driven `contentInset`, so a field in the
/// obscured band is treated as already visible. This helper:
/// 1. Scrolls only when needed (``Placement/minimumVisible``), or pins to the keyboard
///    (``Placement/alignContentToKeyboard``).
/// 2. For ``Placement/minimumVisible`` only, reports how much **extra top inset** is required when
///    content is too short to reveal the field.
@MainActor
enum FKKeyboardVisibleRectScrolling {
  /// Result of computing a reveal for a focused rect.
  struct Adjustment: Equatable {
    /// Temporary top `contentInset` to add above the scroll view’s baseline top inset.
    var extraTopInset: CGFloat
    /// Target `contentOffset.y` after insets are applied.
    var contentOffsetY: CGFloat
  }

  /// How the focused rect should sit inside the unobscured visible band.
  enum Placement {
    /// Scroll only when `rect` would leave the unobscured band (including
    /// `distanceFromKeyboard`); leave offset unchanged when already clear.
    case minimumVisible
    /// Always move offset so `rect.maxY` meets the obscured bottom when reachable, but
    /// **never** expand top inset (no downward pull when already at the top).
    case alignContentToKeyboard
  }

  /// Computes extra top inset + offset so `rect` sits correctly in the visible band.
  ///
  /// - Parameters:
  ///   - rect: Focused view bounds in scroll-view content coordinates (padding already applied).
  ///   - scroll: Target scroll view.
  ///   - baselineTopInset: Scroll view top inset **without** keyboard extra-top (captured original
  ///     `contentInset.top`, optionally plus safe-area contribution already reflected by caller).
  ///   - baselineBottomInset: Scroll view bottom inset **without** keyboard bottom overlap.
  ///   - keyboardBottomInset: Keyboard overlap to apply as bottom inset.
  ///   - distanceFromKeyboard: Gap between focused rect bottom and the unobscured bottom edge.
  ///   - placement: Alignment policy.
  static func adjustment(
    for rect: CGRect,
    in scroll: UIScrollView,
    baselineTopInset: CGFloat,
    baselineBottomInset: CGFloat,
    keyboardBottomInset: CGFloat,
    distanceFromKeyboard: CGFloat,
    placement: Placement
  ) -> Adjustment {
    let bottomInset = baselineBottomInset + max(0, keyboardBottomInset)
    let boundsHeight = scroll.bounds.height
    let contentHeight = scroll.contentSize.height

    switch placement {
    case .minimumVisible:
      let visibleMinY = scroll.contentOffset.y + baselineTopInset
      let visibleMaxY = scroll.contentOffset.y + boundsHeight - bottomInset
      let needsScrollUp = rect.minY < visibleMinY
      let needsScrollDown = rect.maxY + distanceFromKeyboard > visibleMaxY
      guard needsScrollUp || needsScrollDown else {
        return Adjustment(extraTopInset: 0, contentOffsetY: scroll.contentOffset.y)
      }

      var offsetY = scroll.contentOffset.y
      if needsScrollUp {
        offsetY -= visibleMinY - rect.minY
      } else {
        offsetY += rect.maxY + distanceFromKeyboard - visibleMaxY
      }

      // Short content: expand top inset so the field can still enter the visible band.
      let naturalMinOffsetY = -baselineTopInset
      let extraTopInset = max(0, naturalMinOffsetY - offsetY)
      let topInset = baselineTopInset + extraTopInset
      let minOffsetY = -topInset
      let maxOffsetY = max(minOffsetY, contentHeight + bottomInset - boundsHeight)
      offsetY = min(max(offsetY, minOffsetY), maxOffsetY)
      return Adjustment(extraTopInset: extraTopInset, contentOffsetY: offsetY)

    case .alignContentToKeyboard:
      let visibleHeight = boundsHeight - baselineTopInset - bottomInset
      guard visibleHeight > 0 else {
        return Adjustment(extraTopInset: 0, contentOffsetY: scroll.contentOffset.y)
      }

      let idealOffsetY: CGFloat
      if rect.height + distanceFromKeyboard >= visibleHeight {
        idealOffsetY = rect.minY - baselineTopInset
      } else {
        idealOffsetY = rect.maxY + distanceFromKeyboard + bottomInset - boundsHeight
      }

      // Clamp only — do not pull past the natural top.
      let minOffsetY = -baselineTopInset
      let maxOffsetY = max(minOffsetY, contentHeight + bottomInset - boundsHeight)
      let offsetY = min(max(idealOffsetY, minOffsetY), maxOffsetY)
      return Adjustment(extraTopInset: 0, contentOffsetY: offsetY)
    }
  }

  /// Applies a previously computed ``Adjustment`` to `scroll` (offset only; insets must already match).
  static func applyOffset(_ adjustment: Adjustment, to scroll: UIScrollView) {
    guard abs(adjustment.contentOffsetY - scroll.contentOffset.y) > 0.5 else { return }
    scroll.contentOffset = CGPoint(x: scroll.contentOffset.x, y: adjustment.contentOffsetY)
  }
}
