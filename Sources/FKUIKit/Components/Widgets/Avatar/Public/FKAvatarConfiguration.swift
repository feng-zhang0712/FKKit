import UIKit

/// Layout parameters for ``FKAvatar``.
public struct FKAvatarLayoutConfiguration: Sendable, Equatable {
  /// Preset or custom avatar diameter.
  public var size: FKAvatarSize
  /// Clipping shape applied to content.
  public var shape: FKAvatarShape

  /// Creates layout configuration.
  public init(
    size: FKAvatarSize = .m,
    shape: FKAvatarShape = .circle
  ) {
    self.size = size
    self.shape = shape
  }
}

/// Story-ring preset (opt-in gradient ring around the avatar).
public struct FKAvatarStoryRingConfiguration: @unchecked Sendable, Equatable {
  /// Ring thickness in points.
  public var width: CGFloat
  /// Gradient colors (leading → trailing).
  public var gradientColors: [UIColor]
  /// Gap between avatar edge and inner ring edge.
  public var padding: CGFloat

  /// Creates story ring styling.
  public init(
    width: CGFloat = 2.5,
    gradientColors: [UIColor] = [.systemPink, .systemOrange, .systemPurple],
    padding: CGFloat = 2
  ) {
    self.width = max(1, width)
    self.gradientColors = gradientColors.isEmpty ? [.systemPink, .systemOrange] : gradientColors
    self.padding = max(0, padding)
  }
}

extension FKAvatarStoryRingConfiguration {
  public static func == (lhs: FKAvatarStoryRingConfiguration, rhs: FKAvatarStoryRingConfiguration) -> Bool {
    lhs.width == rhs.width && lhs.padding == rhs.padding
  }
}

/// Visual styling for ``FKAvatar``.
public struct FKAvatarAppearanceConfiguration: @unchecked Sendable, Equatable {
  /// Optional stroke around avatar content.
  public var borderStyle: FKLayerBorderStyle
  /// Optional outer story gradient ring.
  public var storyRing: FKAvatarStoryRingConfiguration?
  /// Typography for initials fallback.
  public var initialsFont: UIFont
  /// Text color for initials.
  public var initialsTextColor: UIColor
  /// Placeholder glyph tint when no image or name is available.
  public var placeholderTintColor: UIColor
  /// Template symbol name for placeholder (`person.fill`).
  public var placeholderSymbolName: String
  /// When `true`, overlays a small verified badge icon.
  public var showsVerifiedBadge: Bool
  /// Verified badge symbol name.
  public var verifiedBadgeSymbolName: String
  /// Verified badge tint.
  public var verifiedBadgeTintColor: UIColor
  /// When `true`, URL loads show ``FKSkeletonView``; when `false`, loading chrome comes from embedded ``FKImageView`` only (recommended for lists).
  public var prefersSkeletonLoadingIndicator: Bool

  /// Creates appearance configuration.
  public init(
    borderStyle: FKLayerBorderStyle = .none,
    storyRing: FKAvatarStoryRingConfiguration? = nil,
    initialsFont: UIFont = .systemFont(ofSize: 16, weight: .semibold),
    initialsTextColor: UIColor = .white,
    placeholderTintColor: UIColor = .tertiaryLabel,
    placeholderSymbolName: String = "person.fill",
    showsVerifiedBadge: Bool = false,
    verifiedBadgeSymbolName: String = "checkmark.seal.fill",
    verifiedBadgeTintColor: UIColor = .systemBlue,
    prefersSkeletonLoadingIndicator: Bool = false
  ) {
    self.borderStyle = borderStyle
    self.storyRing = storyRing
    self.initialsFont = initialsFont
    self.initialsTextColor = initialsTextColor
    self.placeholderTintColor = placeholderTintColor
    self.placeholderSymbolName = placeholderSymbolName
    self.showsVerifiedBadge = showsVerifiedBadge
    self.verifiedBadgeSymbolName = verifiedBadgeSymbolName
    self.verifiedBadgeTintColor = verifiedBadgeTintColor
    self.prefersSkeletonLoadingIndicator = prefersSkeletonLoadingIndicator
  }
}

extension FKAvatarAppearanceConfiguration {
  public static func == (lhs: FKAvatarAppearanceConfiguration, rhs: FKAvatarAppearanceConfiguration) -> Bool {
    lhs.borderStyle == rhs.borderStyle
      && lhs.placeholderSymbolName == rhs.placeholderSymbolName
      && lhs.showsVerifiedBadge == rhs.showsVerifiedBadge
      && lhs.verifiedBadgeSymbolName == rhs.verifiedBadgeSymbolName
  }
}

/// Interaction and loading retry behavior for ``FKAvatar``.
public struct FKAvatarInteractionConfiguration: Sendable, Equatable {
  /// When `true`, expands hit testing to at least ``minimumHitAreaSize``.
  public var expandsHitAreaToMinimumSize: Bool
  /// Minimum tappable size (HIG 44×44 pt).
  public var minimumHitAreaSize: CGSize
  /// Subtle scale-down on highlight (respects Reduce Motion).
  public var highlightsOnPress: Bool
  /// Highlight scale factor (1 = no scale).
  public var highlightScale: CGFloat
  /// When `true`, tapping a failed URL load retries the fetch.
  public var retriesOnFailure: Bool

  /// Creates interaction configuration.
  public init(
    expandsHitAreaToMinimumSize: Bool = true,
    minimumHitAreaSize: CGSize = CGSize(width: 44, height: 44),
    highlightsOnPress: Bool = true,
    highlightScale: CGFloat = 0.96,
    retriesOnFailure: Bool = true
  ) {
    self.expandsHitAreaToMinimumSize = expandsHitAreaToMinimumSize
    self.minimumHitAreaSize = minimumHitAreaSize
    self.highlightsOnPress = highlightsOnPress
    self.highlightScale = min(1, max(0.8, highlightScale))
    self.retriesOnFailure = retriesOnFailure
  }
}

/// VoiceOver settings for ``FKAvatar``.
public struct FKAvatarAccessibilityConfiguration: Sendable, Equatable {
  /// When non-`nil`, overrides the default avatar label template.
  public var customLabel: String?
  /// When non-`nil`, appended as accessibility hint.
  public var hint: String?
  /// When `true`, posts accessibility announcements for loading and failure transitions.
  public var announcesLoadingStateChanges: Bool

  /// Creates accessibility configuration.
  public init(
    customLabel: String? = nil,
    hint: String? = nil,
    announcesLoadingStateChanges: Bool = true
  ) {
    self.customLabel = customLabel
    self.hint = hint
    self.announcesLoadingStateChanges = announcesLoadingStateChanges
  }
}

/// Layered configuration for ``FKAvatar``.
public struct FKAvatarConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKAvatarLayoutConfiguration
  public var appearance: FKAvatarAppearanceConfiguration
  public var interaction: FKAvatarInteractionConfiguration
  public var accessibility: FKAvatarAccessibilityConfiguration
  /// Optional presence state rendered at the bottom-trailing edge.
  public var presenceState: FKPresenceState?
  /// Presence styling; uses defaults when `nil`.
  public var presenceConfiguration: FKPresenceIndicatorConfiguration?
  /// When `true` and ``presenceState`` is non-`nil`, shows ``FKPresenceIndicator``.
  public var showsPresenceIndicator: Bool

  /// Creates avatar configuration.
  public init(
    layout: FKAvatarLayoutConfiguration = .init(),
    appearance: FKAvatarAppearanceConfiguration = .init(),
    interaction: FKAvatarInteractionConfiguration = .init(),
    accessibility: FKAvatarAccessibilityConfiguration = .init(),
    presenceState: FKPresenceState? = nil,
    presenceConfiguration: FKPresenceIndicatorConfiguration? = nil,
    showsPresenceIndicator: Bool = false
  ) {
    self.layout = layout
    self.appearance = appearance
    self.interaction = interaction
    self.accessibility = accessibility
    self.presenceState = presenceState
    self.presenceConfiguration = presenceConfiguration
    self.showsPresenceIndicator = showsPresenceIndicator
  }
}

extension FKAvatarConfiguration {
  public static func == (lhs: FKAvatarConfiguration, rhs: FKAvatarConfiguration) -> Bool {
    lhs.layout == rhs.layout
      && lhs.interaction == rhs.interaction
      && lhs.accessibility == rhs.accessibility
      && lhs.presenceState == rhs.presenceState
      && lhs.showsPresenceIndicator == rhs.showsPresenceIndicator
  }
}

/// Thread-safe global defaults for ``FKAvatar``.
public enum FKAvatarDefaults {
  /// Baseline configuration copied by ``FKAvatar/init(frame:)``.
  @MainActor public static var configuration = FKAvatarConfiguration()
}
