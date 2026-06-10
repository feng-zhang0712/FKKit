import CoreGraphics

/// Preset avatar diameters shared by ``FKAvatar`` and ``FKAvatarGroup``.
public enum FKAvatarSize: Sendable, Equatable {
  /// 24 pt — dense lists.
  case xs
  /// 32 pt — navigation bar and group default.
  case s
  /// 40 pt — standard row avatar.
  case m
  /// 48 pt — profile sections.
  case l
  /// 72 pt — profile header.
  case xl
  /// Custom diameter in points (clamped to at least 16 pt when resolved).
  case custom(diameter: CGFloat)

  /// Resolved diameter in points.
  public var diameter: CGFloat {
    switch self {
    case .xs: 24
    case .s: 32
    case .m: 40
    case .l: 48
    case .xl: 72
    case .custom(let diameter):
      max(16, diameter)
    }
  }
}
