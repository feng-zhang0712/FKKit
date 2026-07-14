import CoreGraphics
import UIKit

/// How much layout work to perform while the user is dragging a sheet.
enum FKInteractiveLayoutUpdateKind {
  /// Finger-tracking updates: avoid shadow/keyboard work every frame.
  case tracking
  /// One-shot snap while scroll owns the gesture.
  case settling
  /// Full chrome/layout refresh.
  case full
}

enum FKSheetPresentationInteractionSupport {
  /// Scroll-style rubber-band for dismiss overshoot (points).
  static func rubberBandOffset(_ offset: CGFloat, dimension: CGFloat) -> CGFloat {
    guard offset > 0, dimension > 0 else { return max(0, offset) }
    let coefficient: CGFloat = 0.52
    return (coefficient * offset * dimension) / (dimension + coefficient * offset)
  }

  /// Spring duration scaled by travel distance and release velocity.
  static func adaptiveDetentSnapDuration(distance: CGFloat, velocityY: CGFloat) -> TimeInterval {
    let base = 0.24 + min(0.2, distance / 720)
    let speed = abs(velocityY)
    guard speed > 250 else { return base }
    let speedFactor = min(0.38, speed / 3600)
    return max(0.2, base * (1 - speedFactor))
  }

  /// Normalized vertical spring velocity for detent snapping.
  static func normalizedDetentSnapVelocity(velocityY: CGFloat, distance: CGFloat) -> CGVector {
    let distance = max(1, distance)
    let normalized = min(1.2, max(-1.2, velocityY / distance))
    return CGVector(dx: 0, dy: normalized * 0.82)
  }

  /// Applies combined translation + subtle scale for center interactive dismiss tracking.
  ///
  /// Only downward drag (positive `translationY`) moves/scales the card; upward pans are ignored.
  ///
  /// - Parameter keyboardOffsetY: Optional keyboard-avoidance translation already applied to the wrapper
  ///   (negative moves up). Composed so interactive dismiss does not clobber keyboard offset.
  static func centerDismissTransform(
    translationY: CGFloat,
    containerHeight: CGFloat,
    keyboardOffsetY: CGFloat = 0
  ) -> CGAffineTransform {
    let keyboard = CGAffineTransform(translationX: 0, y: keyboardOffsetY)
    guard translationY > 0 else { return keyboard }
    let dimension = max(1, containerHeight * 0.42)
    let bandedY = rubberBandOffset(translationY, dimension: dimension)
    let progress = min(1, translationY / dimension)
    let scale = max(0.9, 1 - progress * 0.1)
    let dismiss = CGAffineTransform(translationX: 0, y: bandedY).scaledBy(x: scale, y: scale)
    return keyboard.concatenating(dismiss)
  }

  /// Progress used for center-card dismiss thresholding (raw pull over a fraction of container height).
  static func centerDismissProgress(translationY: CGFloat, containerHeight: CGFloat) -> CGFloat {
    let downward = max(0, translationY)
    return min(max(downward / max(1, containerHeight * 0.4), 0), 1)
  }
}
