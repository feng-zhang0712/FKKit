import CoreGraphics
import Foundation
import UIKit

/// A stickable view registration managed by ``FKStickyEngine``.
@MainActor
public final class FKStickyTarget {
  /// Stable identifier used for lookup, removal, and force-stick.
  public let id: String

  /// The view to pin. Held weakly so hosts can release content independently.
  public weak var view: UIView?

  /// When `false`, the target is ignored by layout passes and restored to idle if previously stuck.
  public var isEnabled: Bool

  /// Tie-breaker when two targets share the same natural content position. Higher wins the pin line.
  public var priority: Int

  /// Optional per-target inset that replaces the engine sticky inset for this target only.
  public var stickyInsetOverride: CGFloat?

  /// Invoked when progress or state changes (throttled by engine epsilon).
  public var onProgressChange: ((FKStickyProgress) -> Void)?

  /// Invoked once when entering ``FKStickyState/sticking`` from ``FKStickyState/idle``.
  public var onWillStick: (() -> Void)?

  /// Invoked once when entering ``FKStickyState/stuck``.
  public var onDidStick: (() -> Void)?

  /// Invoked once when returning to ``FKStickyState/idle`` after being stuck or unsticking.
  public var onDidUnstick: (() -> Void)?

  /// Creates a sticky target.
  ///
  /// - Parameters:
  ///   - id: Unique id within the owning engine.
  ///   - view: Stickable content view (typically a descendant of the scroll view’s content).
  ///   - isEnabled: Initial enable flag.
  ///   - priority: Tie-breaker priority.
  ///   - stickyInsetOverride: Optional inset override.
  ///   - onProgressChange: Optional progress callback.
  public init(
    id: String,
    view: UIView,
    isEnabled: Bool = true,
    priority: Int = 0,
    stickyInsetOverride: CGFloat? = nil,
    onProgressChange: ((FKStickyProgress) -> Void)? = nil
  ) {
    self.id = id
    self.view = view
    self.isEnabled = isEnabled
    self.priority = priority
    self.stickyInsetOverride = stickyInsetOverride
    self.onProgressChange = onProgressChange
  }
}
