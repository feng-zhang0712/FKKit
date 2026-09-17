import CoreGraphics
import Foundation
import UIKit

/// Engine-wide sticky behavior configuration.
///
/// Prefer mutating a copy and assigning back to ``FKStickyEngine/configuration``, or set fields
/// on the engine’s configuration before adding targets.
public struct FKStickyConfiguration: Sendable, Equatable {
  /// Master enable switch. When `false`, all targets return to idle on the next layout pass.
  public var isEnabled: Bool

  /// Viewport edge used as the pin line.
  public var edge: FKStickyEdge

  /// Extra inset beyond `UIScrollView.adjustedContentInset` along the sticky edge.
  ///
  /// Ignored when ``FKStickyEngine/stickyInsetProvider`` is non-`nil`.
  public var stickyInset: CGFloat

  /// When `true`, the engine observes scroll metrics via KVO.
  ///
  /// Set to `false` when the host already forwards scroll events and will call
  /// ``FKStickyEngine/handleScroll()``.
  public var observesAutomatically: Bool

  /// When `true`, inserts a same-size placeholder in the original superview while stuck.
  public var preservesPlaceholder: Bool

  /// How multiple stuck targets interact. Defaults to ``FKStickyCollisionBehavior/pushOff``.
  public var collisionBehavior: FKStickyCollisionBehavior

  /// Convenience for ``collisionBehavior``.
  ///
  /// - `true` maps to ``FKStickyCollisionBehavior/pushOff``.
  /// - `false` maps to ``FKStickyCollisionBehavior/stack`` (avoids overlapping pins).
  public var allowsPushOff: Bool {
    get { collisionBehavior == .pushOff }
    set { collisionBehavior = newValue ? .pushOff : .stack }
  }

  /// Distance in points used to ramp ``FKStickyProgress/value`` while crossing the threshold.
  public var transitionDistance: CGFloat

  /// Extra distance past the pin threshold required before an already-stuck target unsticks.
  ///
  /// Reduces flicker when scrolling oscillates around the threshold. `0` preserves exact threshold behavior.
  public var unstickHysteresis: CGFloat

  /// When `true`, the engine applies a simple shadow while a target is stuck.
  ///
  /// Prefer host-side styling via progress callbacks when you need design-system shadows.
  public var appliesStuckShadow: Bool

  /// Shadow opacity applied when ``appliesStuckShadow`` is `true`.
  public var stuckShadowOpacity: Float

  /// Shadow radius applied when ``appliesStuckShadow`` is `true`.
  public var stuckShadowRadius: CGFloat

  /// Shadow offset applied when ``appliesStuckShadow`` is `true`.
  public var stuckShadowOffset: CGSize

  /// Creates a configuration with safe defaults for top-edge scroll sticky.
  public init(
    isEnabled: Bool = true,
    edge: FKStickyEdge = .top,
    stickyInset: CGFloat = 0,
    observesAutomatically: Bool = true,
    preservesPlaceholder: Bool = true,
    collisionBehavior: FKStickyCollisionBehavior = .pushOff,
    allowsPushOff: Bool? = nil,
    transitionDistance: CGFloat = 8,
    unstickHysteresis: CGFloat = 0,
    appliesStuckShadow: Bool = false,
    stuckShadowOpacity: Float = 0.12,
    stuckShadowRadius: CGFloat = 4,
    stuckShadowOffset: CGSize = CGSize(width: 0, height: 2)
  ) {
    self.isEnabled = isEnabled
    self.edge = edge
    self.stickyInset = stickyInset
    self.observesAutomatically = observesAutomatically
    self.preservesPlaceholder = preservesPlaceholder
    if let allowsPushOff {
      self.collisionBehavior = allowsPushOff ? .pushOff : .stack
    } else {
      self.collisionBehavior = collisionBehavior
    }
    self.transitionDistance = max(transitionDistance, 0.1)
    self.unstickHysteresis = max(unstickHysteresis, 0)
    self.appliesStuckShadow = appliesStuckShadow
    self.stuckShadowOpacity = stuckShadowOpacity
    self.stuckShadowRadius = stuckShadowRadius
    self.stuckShadowOffset = stuckShadowOffset
  }

  /// Default top-edge sticky configuration.
  public static let `default` = FKStickyConfiguration()
}
