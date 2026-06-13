import CoreGraphics
import UIKit

/// Presence indicator diameter presets.
public enum FKPresenceIndicatorSize: Sendable, Equatable {
  /// 8 pt — pairs with ``FKAvatarSize/xs``.
  case s
  /// 10 pt — default.
  case m
  /// 12 pt — pairs with ``FKAvatarSize/l`` and ``FKAvatarSize/xl``.
  case l

  /// Resolved diameter in points.
  public var diameter: CGFloat {
    switch self {
    case .s: 8
    case .m: 10
    case .l: 12
    }
  }

  /// Recommended preset for a given avatar diameter.
  public static func recommended(forAvatarDiameter diameter: CGFloat) -> FKPresenceIndicatorSize {
    if diameter <= 24 { return .s }
    if diameter >= 48 { return .l }
    return .m
  }
}

/// Visual and motion settings for ``FKPresenceIndicator``.
public struct FKPresenceIndicatorConfiguration: @unchecked Sendable, Equatable {
  /// Dot diameter preset.
  public var size: FKPresenceIndicatorSize
  /// When `true`, draws a contrast ring around the dot (recommended on photos).
  public var showsBorder: Bool
  /// Border stroke width when ``showsBorder`` is `true`.
  public var borderWidth: CGFloat
  /// Border color; defaults to `systemBackground` at apply time when `nil`.
  public var borderColor: UIColor?
  /// When `true`, ``FKPresenceState/online`` may pulse (respects Reduce Motion).
  public var pulsesWhenOnline: Bool
  /// Minimum pulse cycle duration in seconds.
  public var pulsePeriod: TimeInterval
  /// Override colors per standard state; custom states supply their own color.
  public var stateColors: FKPresenceStateColors

  /// Creates presence indicator configuration.
  public init(
    size: FKPresenceIndicatorSize = .m,
    showsBorder: Bool = true,
    borderWidth: CGFloat = 2,
    borderColor: UIColor? = nil,
    pulsesWhenOnline: Bool = true,
    pulsePeriod: TimeInterval = 1.5,
    stateColors: FKPresenceStateColors = .default
  ) {
    self.size = size
    self.showsBorder = showsBorder
    self.borderWidth = borderWidth
    self.borderColor = borderColor
    self.pulsesWhenOnline = pulsesWhenOnline
    self.pulsePeriod = max(1.5, pulsePeriod)
    self.stateColors = stateColors
  }
}

/// Default fill colors for standard presence states.
public struct FKPresenceStateColors: @unchecked Sendable, Equatable {
  public var online: UIColor
  public var offline: UIColor
  public var busy: UIColor
  public var away: UIColor

  /// System semantic defaults.
  public static let `default` = FKPresenceStateColors(
    online: .systemGreen,
    offline: .systemGray,
    busy: .systemRed,
    away: .systemOrange
  )

  /// Creates state color overrides.
  public init(
    online: UIColor = .systemGreen,
    offline: UIColor = .systemGray,
    busy: UIColor = .systemRed,
    away: UIColor = .systemOrange
  ) {
    self.online = online
    self.offline = offline
    self.busy = busy
    self.away = away
  }
}

extension FKPresenceStateColors {
  public static func == (lhs: FKPresenceStateColors, rhs: FKPresenceStateColors) -> Bool {
    true
  }
}
