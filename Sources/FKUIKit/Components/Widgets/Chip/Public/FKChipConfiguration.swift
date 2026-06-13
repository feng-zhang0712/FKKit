import UIKit

/// Layout parameters for ``FKChip``.
public struct FKChipLayoutConfiguration: Sendable, Equatable {
  public var size: FKChipSize
  public var horizontalPadding: CGFloat
  public var iconSpacing: CGFloat
  public var maxWidth: CGFloat?

  public init(
    size: FKChipSize = .m,
    horizontalPadding: CGFloat = 14,
    iconSpacing: CGFloat = 6,
    maxWidth: CGFloat? = nil
  ) {
    self.size = size
    self.horizontalPadding = horizontalPadding
    self.iconSpacing = iconSpacing
    self.maxWidth = maxWidth
  }
}

/// Visual styling for ``FKChip`` states.
public struct FKChipAppearanceConfiguration: @unchecked Sendable, Equatable {
  public var titleFont: UIFont
  public var normalBackgroundColor: UIColor
  public var normalForegroundColor: UIColor
  public var selectedBackgroundColor: UIColor
  public var selectedForegroundColor: UIColor
  public var disabledAlpha: CGFloat
  public var usesBorderWhenSelected: Bool
  public var selectedBorderColor: UIColor
  public var selectedBorderWidth: CGFloat
  public var cornerStyle: FKChipCornerStyle
  public var removeSymbolName: String

  public init(
    titleFont: UIFont = .systemFont(ofSize: 15, weight: .medium),
    normalBackgroundColor: UIColor = .secondarySystemFill,
    normalForegroundColor: UIColor = .label,
    selectedBackgroundColor: UIColor = .systemBlue,
    selectedForegroundColor: UIColor = .white,
    disabledAlpha: CGFloat = 0.45,
    usesBorderWhenSelected: Bool = false,
    selectedBorderColor: UIColor = .systemBlue,
    selectedBorderWidth: CGFloat = 1.5,
    cornerStyle: FKChipCornerStyle = .capsule,
    removeSymbolName: String = "close"
  ) {
    self.titleFont = titleFont
    self.normalBackgroundColor = normalBackgroundColor
    self.normalForegroundColor = normalForegroundColor
    self.selectedBackgroundColor = selectedBackgroundColor
    self.selectedForegroundColor = selectedForegroundColor
    self.disabledAlpha = disabledAlpha
    self.usesBorderWhenSelected = usesBorderWhenSelected
    self.selectedBorderColor = selectedBorderColor
    self.selectedBorderWidth = selectedBorderWidth
    self.cornerStyle = cornerStyle
    self.removeSymbolName = removeSymbolName
  }
}

extension FKChipAppearanceConfiguration {
  public static func == (lhs: FKChipAppearanceConfiguration, rhs: FKChipAppearanceConfiguration) -> Bool {
    lhs.cornerStyle == rhs.cornerStyle && lhs.removeSymbolName == rhs.removeSymbolName
  }
}

/// Capsule corner strategy.
public enum FKChipCornerStyle: Sendable, Equatable {
  case capsule
  case fixed(CGFloat)
}

/// Interaction and feedback for ``FKChip``.
public struct FKChipInteractionConfiguration: Sendable, Equatable {
  public var expandsHitAreaToMinimumSize: Bool
  public var minimumHitAreaSize: CGSize
  public var highlightsOnPress: Bool
  public var highlightScale: CGFloat
  /// Minimum remove hit extent. Horizontal taps are limited to the trailing gutter beside the title; vertical size is up to this value (clamped to chip height).
  public var removeButtonHitSide: CGFloat
  public var hapticFeedbackOnSelection: Bool

  public init(
    expandsHitAreaToMinimumSize: Bool = true,
    minimumHitAreaSize: CGSize = CGSize(width: 44, height: 44),
    highlightsOnPress: Bool = true,
    highlightScale: CGFloat = 0.97,
    removeButtonHitSide: CGFloat = 44,
    hapticFeedbackOnSelection: Bool = false
  ) {
    self.expandsHitAreaToMinimumSize = expandsHitAreaToMinimumSize
    self.minimumHitAreaSize = minimumHitAreaSize
    self.highlightsOnPress = highlightsOnPress
    self.highlightScale = min(1, max(0.85, highlightScale))
    self.removeButtonHitSide = max(44, removeButtonHitSide)
    self.hapticFeedbackOnSelection = hapticFeedbackOnSelection
  }
}

/// VoiceOver settings for ``FKChip``.
public struct FKChipAccessibilityConfiguration: Sendable, Equatable {
  public var customLabel: String?
  public var customHint: String?
  /// Replaces the default “filter” role word in VoiceOver labels for ``FKChipMode/filter`` and ``FKChipMode/choice``.
  public var filterRoleDescription: String?

  public init(
    customLabel: String? = nil,
    customHint: String? = nil,
    filterRoleDescription: String? = nil
  ) {
    self.customLabel = customLabel
    self.customHint = customHint
    self.filterRoleDescription = filterRoleDescription
  }
}

/// Layered configuration for ``FKChip``.
public struct FKChipConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKChipLayoutConfiguration
  public var appearance: FKChipAppearanceConfiguration
  public var interaction: FKChipInteractionConfiguration
  public var accessibility: FKChipAccessibilityConfiguration

  public init(
    layout: FKChipLayoutConfiguration = .init(),
    appearance: FKChipAppearanceConfiguration = .init(),
    interaction: FKChipInteractionConfiguration = .init(),
    accessibility: FKChipAccessibilityConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.interaction = interaction
    self.accessibility = accessibility
  }
}

extension FKChipConfiguration {
  public static func == (lhs: FKChipConfiguration, rhs: FKChipConfiguration) -> Bool {
    lhs.layout == rhs.layout && lhs.interaction == rhs.interaction && lhs.accessibility == rhs.accessibility
  }
}

/// Thread-safe global defaults for ``FKChip``.
public enum FKChipDefaults {
  @MainActor public static var configuration = FKChipConfiguration()
}
