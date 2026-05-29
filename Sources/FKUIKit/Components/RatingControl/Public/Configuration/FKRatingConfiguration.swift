import UIKit

/// Grouped style, layout, interaction, motion, label, and accessibility settings for ``FKRatingControl``.
public struct FKRatingConfiguration: @unchecked Sendable {
  public var layout: FKRatingLayoutConfiguration
  public var appearance: FKRatingAppearanceConfiguration
  public var interaction: FKRatingInteractionConfiguration
  public var motion: FKRatingMotionConfiguration
  public var label: FKRatingLabelConfiguration
  public var accessibility: FKRatingAccessibilityConfiguration

  public init(
    layout: FKRatingLayoutConfiguration = .init(),
    appearance: FKRatingAppearanceConfiguration = .init(),
    interaction: FKRatingInteractionConfiguration = .init(),
    motion: FKRatingMotionConfiguration = .init(),
    label: FKRatingLabelConfiguration = .init(),
    accessibility: FKRatingAccessibilityConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.interaction = interaction
    self.motion = motion
    self.label = label
    self.accessibility = accessibility
  }
}

// MARK: - Global defaults

/// Namespace for shared defaults applied to new ``FKRatingControl`` instances.
@MainActor
public enum FKRatingDefaults {
  /// Baseline copied at initialization until the host replaces ``FKRatingControl/configuration``.
  public static var configuration = FKRatingConfiguration()
}

/// Convenience namespace mirroring other FKUIKit components.
@MainActor
public enum FKRating {
  /// Baseline style for new ``FKRatingControl`` instances.
  public static var defaultConfiguration: FKRatingConfiguration {
    get { FKRatingDefaults.configuration }
    set { FKRatingDefaults.configuration = newValue }
  }
}
