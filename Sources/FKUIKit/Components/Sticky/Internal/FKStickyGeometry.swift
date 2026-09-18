import CoreGraphics
import UIKit

/// Pure geometry helpers for sticky layout passes.
///
/// Coordinate rules (UIKit):
/// - **Content space** — same space as `UIScrollView` subview frames / `contentSize`.
/// - **Bounds space** — visible area (`content - contentOffset`); overlay / `frameLayoutGuide` uses this.
/// - Stick decisions compare **bounds** frames to the pin line.
@MainActor
enum FKStickyGeometry {
  /// View frame in scroll-view **content** coordinates.
  ///
  /// Walks the superview chain with `convert(_:to:)` until the scroll view. For a `UIScrollView`,
  /// that result is content space (equivalent to accumulating subview frames) — it does **not**
  /// already subtract `contentOffset`.
  static func contentFrame(of view: UIView, in scrollView: UIScrollView) -> CGRect {
    var rect = view.bounds
    var current: UIView = view
    while current !== scrollView {
      guard let parent = current.superview else { return .zero }
      rect = current.convert(rect, to: parent)
      current = parent
    }
    return rect
  }

  /// Whether the scroll view has a usable bounds size for sticky math.
  static func hasUsableBounds(_ scrollView: UIScrollView) -> Bool {
    scrollView.bounds.width > 0.5 && scrollView.bounds.height > 0.5
  }

  /// Rejects content frames produced before the hierarchy is ready (or from stale overlay frames).
  static func isPlausibleContentFrame(_ frame: CGRect, in scrollView: UIScrollView) -> Bool {
    guard frame.height > 0.5, frame.width > 0.5 else { return false }
    // Pre-layout converts can yield large negative origins (e.g. -741) that look "already past"
    // the pin line and cause a premature stick.
    guard frame.minY >= -1, frame.minX >= -scrollView.bounds.width else { return false }
    return true
  }

  /// `contentOffset` clamped to the scrollable range (excludes rubber-band overscroll).
  ///
  /// Stick / unstick and pin math must ignore overscroll — otherwise top/bottom bounce briefly
  /// crosses the release threshold, toggles hosting, fights `contentSize` clamping, and can
  /// cancel the pan so the scroll view feels locked at the end.
  ///
  /// When `contentSize` is still unset (`0`), the empty range would clamp every offset to the
  /// minimum and block the first stick while the user can already bounce. In that window the
  /// raw offset is used until content metrics arrive.
  static func clampedContentOffset(of scrollView: UIScrollView) -> CGPoint {
    let inset = scrollView.adjustedContentInset
    let minX = -inset.left
    let minY = -inset.top
    let offset = scrollView.contentOffset
    let content = scrollView.contentSize

    let maxX: CGFloat
    if content.width > 0.5 {
      maxX = max(minX, content.width - scrollView.bounds.width + inset.right)
    } else {
      maxX = offset.x
    }
    let maxY: CGFloat
    if content.height > 0.5 {
      maxY = max(minY, content.height - scrollView.bounds.height + inset.bottom)
    } else {
      maxY = offset.y
    }

    return CGPoint(
      x: min(max(offset.x, minX), maxX),
      y: min(max(offset.y, minY), maxY)
    )
  }

  /// View frame in the scroll view’s visible **bounds** coordinate system.
  static func frameInScrollBounds(of view: UIView, in scrollView: UIScrollView) -> CGRect {
    let offset = clampedContentOffset(of: scrollView)
    return contentFrame(of: view, in: scrollView)
      .offsetBy(dx: -offset.x, dy: -offset.y)
  }

  /// Content-space origin of `view` inside `scrollView`.
  static func contentOrigin(of view: UIView, in scrollView: UIScrollView) -> CGPoint {
    contentFrame(of: view, in: scrollView).origin
  }

  /// Resolves the effective sticky inset for a target.
  static func resolvedInset(
    configuration: FKStickyConfiguration,
    provider: (() -> CGFloat)?,
    targetOverride: CGFloat?
  ) -> CGFloat {
    if let targetOverride {
      return targetOverride
    }
    if let provider {
      return provider()
    }
    return configuration.stickyInset
  }

  /// Pin line in scroll-view **bounds** coordinates (overlay / `frameLayoutGuide` space).
  static func pinLineViewportY(
    edge: FKStickyEdge,
    scrollView: UIScrollView,
    inset: CGFloat,
    targetHeight: CGFloat
  ) -> CGFloat {
    switch edge {
    case .top:
      return scrollView.adjustedContentInset.top + inset
    case .bottom:
      return scrollView.bounds.height
        - scrollView.adjustedContentInset.bottom
        - inset
        - targetHeight
    }
  }

  /// Whether `view` has reached the pin line in the **visible** scroll view.
  ///
  /// - Parameter hysteresis: Extra release distance applied only when `isCurrentlySticky` is `true`.
  static func hasCrossedThreshold(
    edge: FKStickyEdge,
    view: UIView,
    scrollView: UIScrollView,
    pinLineViewportY: CGFloat,
    targetHeight: CGFloat,
    isCurrentlySticky: Bool,
    hysteresis: CGFloat,
    frozenContentOrigin: CGPoint?
  ) -> Bool {
    let releasePad = isCurrentlySticky ? max(hysteresis, 0) : 0
    let offsetY = clampedContentOffset(of: scrollView).y
    let boundsY: CGFloat
    if isCurrentlySticky, let frozen = frozenContentOrigin {
      // Hosted in the overlay — derive bounds Y from the frozen content origin.
      boundsY = frozen.y - offsetY
    } else {
      let content = contentFrame(of: view, in: scrollView)
      guard isPlausibleContentFrame(content, in: scrollView) else { return false }
      boundsY = content.minY - offsetY
    }

    switch edge {
    case .top:
      return boundsY <= pinLineViewportY + releasePad
    case .bottom:
      let bottomPin = pinLineViewportY + targetHeight
      let boundsMaxY = boundsY + targetHeight
      return boundsMaxY >= bottomPin - releasePad
    }
  }

  /// Distance past the pin line in points (non-negative), used for progress.
  static func distancePastThreshold(
    edge: FKStickyEdge,
    view: UIView,
    scrollView: UIScrollView,
    pinLineViewportY: CGFloat,
    targetHeight: CGFloat,
    isCurrentlySticky: Bool,
    frozenContentOrigin: CGPoint?
  ) -> CGFloat {
    let offsetY = clampedContentOffset(of: scrollView).y
    let boundsY: CGFloat
    if isCurrentlySticky, let frozen = frozenContentOrigin {
      boundsY = frozen.y - offsetY
    } else {
      let content = contentFrame(of: view, in: scrollView)
      guard isPlausibleContentFrame(content, in: scrollView) else { return 0 }
      boundsY = content.minY - offsetY
    }

    switch edge {
    case .top:
      return max(0, pinLineViewportY - boundsY)
    case .bottom:
      let bottomPin = pinLineViewportY + targetHeight
      let boundsMaxY = boundsY + targetHeight
      return max(0, boundsMaxY - bottomPin)
    }
  }

  /// Maps a content X origin into overlay (bounds) X.
  static func viewportX(contentX: CGFloat, scrollView: UIScrollView) -> CGFloat {
    contentX - clampedContentOffset(of: scrollView).x
  }

  /// Maps a content Y origin into overlay (bounds) Y.
  static func viewportY(contentY: CGFloat, scrollView: UIScrollView) -> CGFloat {
    contentY - clampedContentOffset(of: scrollView).y
  }

  /// Frame comparison used to skip no-op sticky frame writes during scroll ticks.
  static func framesApproximatelyEqual(_ lhs: CGRect, _ rhs: CGRect, tolerance: CGFloat = 0.5) -> Bool {
    abs(lhs.minX - rhs.minX) <= tolerance
      && abs(lhs.minY - rhs.minY) <= tolerance
      && abs(lhs.width - rhs.width) <= tolerance
      && abs(lhs.height - rhs.height) <= tolerance
  }
}
