import UIKit

/// Follow mode for tab bar indicator geometry during selection, paging progress, and strip scrolling.
public enum FKTabBarIndicatorFollowMode: Equatable {
  /// Always anchors indicator geometry to the currently selected tab frame.
  ///
  /// During pure tab-bar scrolling (without changing selection), indicator moves together
  /// with the selected tab because frame is resolved in collection coordinates.
  case trackSelectedFrame
  /// Anchors indicator geometry to the rendered content frame of the selected tab.
  ///
  /// This usually produces a tighter line under text/icon content than `trackSelectedFrame`.
  case trackContentFrame
  /// During interactive page progress, interpolates indicator between source and destination tabs.
  ///
  /// Outside interaction, this mode behaves like `trackSelectedFrame`.
  case trackContentProgress
  /// Keeps indicator locked to current selected tab while interaction is in flight.
  ///
  /// Indicator jumps to final tab only after settle/commit. Useful when minimizing visual jitter
  /// is more important than showing continuous progress.
  case lockedUntilSettle
  /// Defers follow behavior selection to host-defined strategy identifier.
  ///
  /// When no host strategy is provided, this mode falls back to `trackSelectedFrame`.
  case custom(id: String)
}

/// Vertical position of line indicator inside item bounds.
public enum FKTabBarLineIndicatorPosition: Equatable {
  case top
  case bottom
  case center
}

/// Line indicator color style.
public enum FKTabBarIndicatorFillStyle: Equatable {
  case solid(UIColor)
  case gradient(colors: [UIColor], startPoint: CGPoint, endPoint: CGPoint)
}

/// Line indicator configuration.
public struct FKTabBarLineIndicatorConfiguration: Equatable {
  public var position: FKTabBarLineIndicatorPosition
  public var thickness: CGFloat
  public var fill: FKTabBarIndicatorFillStyle
  public var leadingInset: CGFloat
  public var trailingInset: CGFloat
  /// When non-`nil`, the line uses this width (clamped to the span after `leadingInset` / `trailingInset`) and is centered horizontally in that span.
  ///
  /// When `nil`, the line spans the full width between insets (existing behavior).
  public var fixedWidth: CGFloat?
  public var cornerRadius: CGFloat
  /// Follow policy controlling how line indicator reacts to selection, progress, and strip scrolling.
  ///
  /// Default is `trackSelectedFrame` for predictable behavior across taps, programmatic selection,
  /// rotation relayout, and manual tab-strip scrolling.
  public var followMode: FKTabBarIndicatorFollowMode

  public init(
    position: FKTabBarLineIndicatorPosition = .bottom,
    thickness: CGFloat = 3,
    fill: FKTabBarIndicatorFillStyle = .solid(.black),
    leadingInset: CGFloat = 8,
    trailingInset: CGFloat = 8,
    fixedWidth: CGFloat? = nil,
    cornerRadius: CGFloat = 1.5,
    followMode: FKTabBarIndicatorFollowMode = .trackSelectedFrame
  ) {
    self.position = position
    self.thickness = thickness
    self.fill = fill
    self.leadingInset = leadingInset
    self.trailingInset = trailingInset
    self.fixedWidth = fixedWidth
    self.cornerRadius = cornerRadius
    self.followMode = followMode
  }
}

/// How ``FKTabBarBackgroundIndicatorConfiguration/cornerRadius`` is applied when rendering a background indicator.
public enum FKTabBarBackgroundIndicatorShape: Equatable {
  /// Corners are capped at half the indicator height (`min(cornerRadius, height/2)`).
  ///
  /// Large `cornerRadius` yields a capsule; smaller values yield a fixed-corner rounded rectangle.
  case roundedRect
  /// End caps are at least semicircular: effective radius is `max(cornerRadius, height/2)`.
  case pill
}

/// Shared configuration for ``FKTabBarIndicatorStyle/backdrop``.
public struct FKTabBarBackgroundIndicatorConfiguration: Equatable {
  public var insets: NSDirectionalEdgeInsets
  /// Corner radius in points before ``shape`` maps it into the laid-out indicator bounds.
  public var cornerRadius: CGFloat
  /// Maps ``cornerRadius`` and indicator height to the layer’s rendered corner radius.
  public var shape: FKTabBarBackgroundIndicatorShape
  /// Fill style for selected background (solid or gradient).
  public var fill: FKTabBarIndicatorFillStyle
  public var borderColor: UIColor
  public var borderWidth: CGFloat
  public var shadowColor: UIColor
  public var shadowOpacity: Float
  public var shadowRadius: CGFloat
  public var shadowOffset: CGSize
  /// Follow policy aligned with ``FKTabBarLineIndicatorConfiguration/followMode`` (default matches line defaults).
  ///
  /// Use ``FKTabBarIndicatorFollowMode/trackContentProgress`` so the highlight tracks interactive paging
  /// between tabs (for example ``FKPagingController`` swipe progress).
  public var followMode: FKTabBarIndicatorFollowMode

  public init(
    insets: NSDirectionalEdgeInsets = .init(top: 4, leading: 6, bottom: 4, trailing: 6),
    cornerRadius: CGFloat = 999,
    shape: FKTabBarBackgroundIndicatorShape = .roundedRect,
    fill: FKTabBarIndicatorFillStyle = .solid(UIColor.secondarySystemFill),
    borderColor: UIColor = .clear,
    borderWidth: CGFloat = 0,
    shadowColor: UIColor = .clear,
    shadowOpacity: Float = 0,
    shadowRadius: CGFloat = 0,
    shadowOffset: CGSize = .zero,
    followMode: FKTabBarIndicatorFollowMode = .trackSelectedFrame
  ) {
    self.insets = insets
    self.cornerRadius = cornerRadius
    self.shape = shape
    self.fill = fill
    self.borderColor = borderColor
    self.borderWidth = borderWidth
    self.shadowColor = shadowColor
    self.shadowOpacity = shadowOpacity
    self.shadowRadius = shadowRadius
    self.shadowOffset = shadowOffset
    self.followMode = followMode
  }
}

/// Configuration for ``FKTabBarIndicatorStyle/custom``.
public struct FKTabBarCustomIndicatorConfiguration: Equatable {
  public var id: String
  /// Same semantics as ``FKTabBarBackgroundIndicatorConfiguration/followMode``.
  public var followMode: FKTabBarIndicatorFollowMode

  public init(id: String, followMode: FKTabBarIndicatorFollowMode = .trackSelectedFrame) {
    self.id = id
    self.followMode = followMode
  }
}

/// Indicator style for selected tab.
public enum FKTabBarIndicatorStyle {
  /// No indicator.
  case none
  /// Full line indicator with precise controls.
  case line(FKTabBarLineIndicatorConfiguration)
  /// Background indicator (solid or gradient) behind the selected item; use ``shape`` on the configuration for rounded rect vs. pill.
  ///
  /// Prefer convenience factories ``FKTabBarIndicatorStyle/background(_:)``, ``gradient(_:)``, or ``pill(_:)`` when you want fixed shape semantics.
  case backdrop(FKTabBarBackgroundIndicatorConfiguration)
  /// Host-provided custom indicator.
  case custom(FKTabBarCustomIndicatorConfiguration)
}

extension FKTabBarIndicatorStyle {
  /// Builds ``FKTabBarIndicatorStyle/custom(FKTabBarCustomIndicatorConfiguration)`` with defaults aligned to ``FKTabBarLineIndicatorConfiguration``.
  public static func custom(id: String, followMode: FKTabBarIndicatorFollowMode = .trackSelectedFrame) -> FKTabBarIndicatorStyle {
    .custom(FKTabBarCustomIndicatorConfiguration(id: id, followMode: followMode))
  }

  /// Background indicator with ``FKTabBarBackgroundIndicatorShape/roundedRect`` (caps `cornerRadius` at `height/2`).
  public static func background(_ configuration: FKTabBarBackgroundIndicatorConfiguration) -> FKTabBarIndicatorStyle {
    var c = configuration
    c.shape = .roundedRect
    return .backdrop(c)
  }

  /// Same as ``background(_:)`` with rounded-rect shape; typical pairing with ``FKTabBarIndicatorFillStyle/gradient(colors:startPoint:endPoint:)``.
  public static func gradient(_ configuration: FKTabBarBackgroundIndicatorConfiguration) -> FKTabBarIndicatorStyle {
    var c = configuration
    c.shape = .roundedRect
    return .backdrop(c)
  }

  /// Background indicator with ``FKTabBarBackgroundIndicatorShape/pill`` semantics.
  public static func pill(_ configuration: FKTabBarBackgroundIndicatorConfiguration) -> FKTabBarIndicatorStyle {
    var c = configuration
    c.shape = .pill
    return .backdrop(c)
  }
}

/// Case identifier set for `FKTabBarIndicatorStyle`.
///
/// Use this in examples/tools to build complete style choosers without hand-maintaining switches.
public enum FKTabBarIndicatorStyleKind: String, CaseIterable {
  case none
  case line
  /// Rounded-rect background (`FKTabBarIndicatorStyle.background`).
  case background
  /// Rounded-rect background with gradient fill (`FKTabBarIndicatorStyle.gradient`).
  case gradient
  case pill
  case custom
}

/// Indicator animation behavior.
public enum FKTabBarIndicatorAnimation: Equatable {
  case none
  case linear(duration: TimeInterval)
  case spring(duration: TimeInterval, damping: CGFloat, velocity: CGFloat)
}

