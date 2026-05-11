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

/// Shared configuration for background-like indicators.
public struct FKTabBarBackgroundIndicatorConfiguration: Equatable {
  public var insets: NSDirectionalEdgeInsets
  /// Corner radius used for background-like indicators.
  ///
  /// - Note: The runtime renderer caps this value to half of the indicator height so passing a
  ///   "large enough" radius produces capsule semantics (\(radius = height / 2\)). This enables:
  ///   - capsule by default
  ///   - fixed rounded-rect by explicitly providing a smaller value
  public var cornerRadius: CGFloat
  /// Fill style for selected background.
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
  /// Background highlight behind selected item.
  case backgroundHighlight(FKTabBarBackgroundIndicatorConfiguration)
  /// Gradient background highlight behind selected item.
  case gradientHighlight(FKTabBarBackgroundIndicatorConfiguration)
  /// Capsule / pill style highlight.
  case pill(FKTabBarBackgroundIndicatorConfiguration)
  /// Host-provided custom indicator.
  case custom(FKTabBarCustomIndicatorConfiguration)
}

extension FKTabBarIndicatorStyle {
  /// Builds ``FKTabBarIndicatorStyle/custom(FKTabBarCustomIndicatorConfiguration)`` with defaults aligned to ``FKTabBarLineIndicatorConfiguration``.
  public static func custom(id: String, followMode: FKTabBarIndicatorFollowMode = .trackSelectedFrame) -> FKTabBarIndicatorStyle {
    .custom(FKTabBarCustomIndicatorConfiguration(id: id, followMode: followMode))
  }
}

/// Case identifier set for `FKTabBarIndicatorStyle`.
///
/// Use this in examples/tools to build complete style choosers without hand-maintaining switches.
public enum FKTabBarIndicatorStyleKind: String, CaseIterable {
  case none
  case line
  case backgroundHighlight
  case gradientHighlight
  case pill
  case custom
}

/// Indicator animation behavior.
public enum FKTabBarIndicatorAnimation: Equatable {
  case none
  case linear(duration: TimeInterval)
  case spring(duration: TimeInterval, damping: CGFloat, velocity: CGFloat)
}

