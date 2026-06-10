import UIKit

/// Horizontal stacking direction for ``FKAvatarGroup``.
public enum FKAvatarGroupDirection: Sendable, Equatable {
  /// First avatar at leading edge; overflow at trailing (mirrors under RTL).
  case leadingToTrailing
  /// First avatar at trailing edge.
  case trailingToLeading
}

/// Layout and styling for ``FKAvatarGroup``.
public struct FKAvatarGroupConfiguration: @unchecked Sendable, Equatable {
  /// Maximum avatars rendered before overflow.
  public var maxVisible: Int
  /// Horizontal overlap between adjacent avatars (negative overlaps).
  public var overlap: CGFloat
  /// When `true`, shows a "+N" overflow affordance.
  public var showsOverflowCount: Bool
  /// Stacking direction (RTL-aware).
  public var direction: FKAvatarGroupDirection
  /// Uniform avatar size inside the group.
  public var avatarSize: FKAvatarSize
  /// Optional white separator stroke between overlapping avatars.
  public var borderStyle: FKLayerBorderStyle
  /// Base avatar configuration applied to each child ``FKAvatar`` (presence typically off in groups).
  public var avatarConfiguration: FKAvatarConfiguration

  /// Creates group configuration.
  public init(
    maxVisible: Int = 4,
    overlap: CGFloat = -8,
    showsOverflowCount: Bool = true,
    direction: FKAvatarGroupDirection = .leadingToTrailing,
    avatarSize: FKAvatarSize = .s,
    borderStyle: FKLayerBorderStyle = .none,
    avatarConfiguration: FKAvatarConfiguration = .init()
  ) {
    self.maxVisible = max(1, maxVisible)
    self.overlap = overlap
    self.showsOverflowCount = showsOverflowCount
    self.direction = direction
    self.avatarSize = avatarSize
    self.borderStyle = borderStyle
    self.avatarConfiguration = avatarConfiguration
  }
}

extension FKAvatarGroupConfiguration {
  public static func == (lhs: FKAvatarGroupConfiguration, rhs: FKAvatarGroupConfiguration) -> Bool {
    lhs.maxVisible == rhs.maxVisible
      && lhs.overlap == rhs.overlap
      && lhs.showsOverflowCount == rhs.showsOverflowCount
      && lhs.direction == rhs.direction
      && lhs.avatarSize == rhs.avatarSize
      && lhs.borderStyle == rhs.borderStyle
  }
}

/// Thread-safe global defaults for ``FKAvatarGroup``.
public enum FKAvatarGroupDefaults {
  /// Baseline configuration copied by ``FKAvatarGroup/init(frame:)``.
  @MainActor public static var configuration = FKAvatarGroupConfiguration()
}
