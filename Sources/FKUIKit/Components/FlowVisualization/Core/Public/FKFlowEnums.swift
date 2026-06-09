import QuartzCore
import UIKit

/// Node geometry presets shared by step indicator and timeline.
public enum FKFlowNodeShape: Sendable, Equatable, Hashable {
  /// Circular node (default).
  case circle
  /// Rounded rectangle for audit-style logs.
  case roundedSquare
  /// Map-pin style node for tracking UIs.
  case pin
}

/// Node diameter presets.
public enum FKFlowNodeSize: Sendable, Equatable, Hashable {
  /// 20 pt node.
  case small
  /// 28 pt node (default).
  case medium
  /// 36 pt node.
  case large

  /// Resolved diameter in points before Dynamic Type scaling.
  public var diameter: CGFloat {
    switch self {
    case .small: return 20
    case .medium: return 28
    case .large: return 36
    }
  }
}

/// Vertical and horizontal spacing presets.
public enum FKFlowDensity: Sendable, Equatable, Hashable {
  /// Default title spacing and line limits.
  case regular
  /// Tighter track and single-line titles.
  case compact
  /// Extra vertical spacing (timeline).
  case spacious
}

/// Horizontal step indicator layout modes.
public enum FKStepIndicatorLayout: Sendable, Equatable, Hashable {
  /// Rail on top, titles below nodes (default).
  case horizontalTopLabels
  /// Titles above nodes.
  case horizontalBottomLabels
  /// Titles beside nodes (best for 2–3 steps).
  case horizontalInline
  /// Small nodes with optional horizontal scrolling.
  case compactDots
}

/// Vertical timeline layout modes.
public enum FKTimelineLayout: Sendable, Equatable, Hashable {
  /// Rail on the leading edge in LTR (default).
  case verticalLeadingRail
  /// Rail on the trailing edge.
  case verticalTrailingRail
  /// Alternating rail side by row index. Reserved for a future release; currently mirrors ``verticalLeadingRail``.
  case verticalAlternating
  /// Reduced padding for embedding in lists.
  case embeddedInList
}

/// How timeline rows format timestamps.
public enum FKTimelineTimestampStyle: Sendable, Equatable, Hashable {
  /// Relative time via `RelativeDateTimeFormatter`.
  case relative
  /// Short absolute date and time.
  case absolute
  /// Uses ``FKFlowStepItem/formattedTimestamp``.
  case custom
  /// Hides the timestamp row.
  case hidden
}

/// Connector continuation below the last timeline node.
public enum FKTimelineTailStyle: Sendable, Equatable, Hashable {
  /// No line after the last node.
  case none
  /// Faded dotted tail (in-progress delivery).
  case dotted
  /// Dashed line toward a future placeholder event.
  case toFuture
}

/// Animation timing curve for flow transitions.
public enum FKFlowTiming: Sendable, Equatable, Hashable {
  case `default`
  case easeIn
  case easeOut
  case linear

  func mediaTimingFunction() -> CAMediaTimingFunction {
    switch self {
    case .default: return CAMediaTimingFunction(name: .default)
    case .easeIn: return CAMediaTimingFunction(name: .easeIn)
    case .easeOut: return CAMediaTimingFunction(name: .easeOut)
    case .linear: return CAMediaTimingFunction(name: .linear)
    }
  }
}
