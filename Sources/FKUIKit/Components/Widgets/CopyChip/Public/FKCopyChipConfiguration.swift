import UIKit

/// Capsule height presets for ``FKCopyChip``.
public enum FKCopyChipSize: Sendable, Equatable {
  /// 28 pt — compact order/ID chips.
  case s
  /// 36 pt — default tap target with readable monospace IDs.
  case m
  /// Custom height (clamped to at least 24 pt).
  case custom(height: CGFloat)

  /// Resolved control height in points.
  public var height: CGFloat {
    switch self {
    case .s: 28
    case .m: 36
    case .custom(let height):
      max(24, height)
    }
  }
}

/// Display truncation strategy for ``FKCopyChip/text``.
public enum FKCopyChipTruncation: Sendable, Equatable {
  /// Show the full display string (subject to label line break mode).
  case none
  /// Keep at most `maxCharacters` from the start.
  case tail(maxCharacters: Int)
  /// Middle ellipsis, e.g. `A1288…9F2`.
  case middle(prefixLength: Int, suffixLength: Int)
}

/// Post-copy feedback mode for ``FKCopyChip``.
public enum FKCopyChipFeedback: Sendable, Equatable {
  /// No toast, haptic, or spoken announcement.
  case none
  /// Light impact haptic only.
  case hapticOnly
  /// ``FKToast`` success banner with optional haptic.
  case toast
}

/// Layout parameters for ``FKCopyChip``.
public struct FKCopyChipLayoutConfiguration: Sendable, Equatable {
  public var size: FKCopyChipSize
  public var horizontalPadding: CGFloat
  public var iconSpacing: CGFloat
  /// Optional static prefix prepended to ``FKCopyChip/text`` for display (e.g. `Order #`).
  public var prefix: String?
  public var truncation: FKCopyChipTruncation

  public init(
    size: FKCopyChipSize = .m,
    horizontalPadding: CGFloat = 12,
    iconSpacing: CGFloat = 6,
    prefix: String? = nil,
    truncation: FKCopyChipTruncation = .none
  ) {
    self.size = size
    self.horizontalPadding = horizontalPadding
    self.iconSpacing = iconSpacing
    self.prefix = prefix
    self.truncation = truncation
  }
}

/// Visual styling for ``FKCopyChip``.
public struct FKCopyChipAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var titleFont: UIFont
  public var usesMonospacedFont: Bool
  public var backgroundColor: UIColor
  public var foregroundColor: UIColor
  public var iconColor: UIColor
  public var cornerStyle: FKCopyChipCornerStyle
  public var copySymbolName: String
  public var successFlashColor: UIColor?
  public var disabledAlpha: CGFloat

  public init(
    titleFont: UIFont = .systemFont(ofSize: 15, weight: .medium),
    usesMonospacedFont: Bool = false,
    backgroundColor: UIColor = .secondarySystemFill,
    foregroundColor: UIColor = .label,
    iconColor: UIColor = .secondaryLabel,
    cornerStyle: FKCopyChipCornerStyle = .capsule,
    copySymbolName: String = "doc.on.doc",
    successFlashColor: UIColor? = nil,
    disabledAlpha: CGFloat = 0.45
  ) {
    self.titleFont = titleFont
    self.usesMonospacedFont = usesMonospacedFont
    self.backgroundColor = backgroundColor
    self.foregroundColor = foregroundColor
    self.iconColor = iconColor
    self.cornerStyle = cornerStyle
    self.copySymbolName = copySymbolName
    self.successFlashColor = successFlashColor
    self.disabledAlpha = disabledAlpha
  }
}

extension FKCopyChipAppearanceConfiguration {
  public static func == (lhs: FKCopyChipAppearanceConfiguration, rhs: FKCopyChipAppearanceConfiguration) -> Bool {
    lhs.usesMonospacedFont == rhs.usesMonospacedFont
      && lhs.cornerStyle == rhs.cornerStyle
      && lhs.copySymbolName == rhs.copySymbolName
      && lhs.disabledAlpha == rhs.disabledAlpha
  }
}

/// Capsule or fixed corner radius.
public enum FKCopyChipCornerStyle: Sendable, Equatable {
  case capsule
  case fixed(CGFloat)
}

/// Interaction and pasteboard options for ``FKCopyChip``.
public struct FKCopyChipInteractionConfiguration: Sendable, Equatable {
  public var expandsHitAreaToMinimumSize: Bool
  public var minimumHitAreaSize: CGSize
  public var highlightsOnPress: Bool
  public var highlightScale: CGFloat
  /// Optional pasteboard expiration (iOS may still show the pasteboard access indicator).
  public var pasteboardExpirationDate: Date?

  public init(
    expandsHitAreaToMinimumSize: Bool = true,
    minimumHitAreaSize: CGSize = CGSize(width: 44, height: 44),
    highlightsOnPress: Bool = true,
    highlightScale: CGFloat = 0.97,
    pasteboardExpirationDate: Date? = nil
  ) {
    self.expandsHitAreaToMinimumSize = expandsHitAreaToMinimumSize
    self.minimumHitAreaSize = minimumHitAreaSize
    self.highlightsOnPress = highlightsOnPress
    self.highlightScale = min(1, max(0.85, highlightScale))
    self.pasteboardExpirationDate = pasteboardExpirationDate
  }
}

/// Feedback after a successful copy for ``FKCopyChip``.
public struct FKCopyChipFeedbackConfiguration: @unchecked Sendable, Equatable {
  public var mode: FKCopyChipFeedback
  /// Overrides the default toast message when ``mode`` is ``FKCopyChipFeedback/toast``.
  public var toastMessage: String?
  /// When ``mode`` is ``FKCopyChipFeedback/toast``, optionally play haptic alongside the toast.
  public var playsHapticWithToast: Bool
  public var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
  public var postsAccessibilityAnnouncement: Bool
  /// Brief background color pulse after copy; ignored when ``mode`` is ``FKCopyChipFeedback/none``.
  public var playsSuccessFlash: Bool

  public init(
    mode: FKCopyChipFeedback = .toast,
    toastMessage: String? = nil,
    playsHapticWithToast: Bool = false,
    hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light,
    postsAccessibilityAnnouncement: Bool = true,
    playsSuccessFlash: Bool = true
  ) {
    self.mode = mode
    self.toastMessage = toastMessage
    self.playsHapticWithToast = playsHapticWithToast
    self.hapticStyle = hapticStyle
    self.postsAccessibilityAnnouncement = postsAccessibilityAnnouncement
    self.playsSuccessFlash = playsSuccessFlash
  }
}

/// VoiceOver settings for ``FKCopyChip``.
public struct FKCopyChipAccessibilityConfiguration: Sendable, Equatable {
  public var customLabel: String?
  public var customHint: String?

  public init(customLabel: String? = nil, customHint: String? = nil) {
    self.customLabel = customLabel
    self.customHint = customHint
  }
}

/// Layered configuration for ``FKCopyChip``.
public struct FKCopyChipConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKCopyChipLayoutConfiguration
  public var appearance: FKCopyChipAppearanceConfiguration
  public var interaction: FKCopyChipInteractionConfiguration
  public var feedback: FKCopyChipFeedbackConfiguration
  public var accessibility: FKCopyChipAccessibilityConfiguration

  public init(
    layout: FKCopyChipLayoutConfiguration = .init(),
    appearance: FKCopyChipAppearanceConfiguration = .init(),
    interaction: FKCopyChipInteractionConfiguration = .init(),
    feedback: FKCopyChipFeedbackConfiguration = .init(),
    accessibility: FKCopyChipAccessibilityConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.interaction = interaction
    self.feedback = feedback
    self.accessibility = accessibility
  }
}

extension FKCopyChipConfiguration {
  public static func == (lhs: FKCopyChipConfiguration, rhs: FKCopyChipConfiguration) -> Bool {
    lhs.layout == rhs.layout
      && lhs.interaction == rhs.interaction
      && lhs.feedback == rhs.feedback
      && lhs.accessibility == rhs.accessibility
  }
}

extension FKCopyChipFeedbackConfiguration {
  public static func == (lhs: FKCopyChipFeedbackConfiguration, rhs: FKCopyChipFeedbackConfiguration) -> Bool {
    lhs.mode == rhs.mode
      && lhs.toastMessage == rhs.toastMessage
      && lhs.playsHapticWithToast == rhs.playsHapticWithToast
      && lhs.hapticStyle == rhs.hapticStyle
      && lhs.postsAccessibilityAnnouncement == rhs.postsAccessibilityAnnouncement
      && lhs.playsSuccessFlash == rhs.playsSuccessFlash
  }
}

/// Thread-safe global defaults for ``FKCopyChip``.
public enum FKCopyChipDefaults {
  @MainActor public static var configuration = FKCopyChipConfiguration()
}
