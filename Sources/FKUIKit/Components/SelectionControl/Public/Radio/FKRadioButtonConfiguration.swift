import Foundation

/// Grouped configuration for ``FKRadioButton``.
public struct FKRadioButtonConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKRadioButtonLayoutConfiguration
  public var appearance: FKRadioButtonAppearanceConfiguration
  public var interaction: FKRadioButtonInteractionConfiguration
  public var motion: FKSelectionControlMotionConfiguration
  public var accessibility: FKSelectionControlAccessibilityConfiguration

  public init(
    layout: FKRadioButtonLayoutConfiguration = .init(),
    appearance: FKRadioButtonAppearanceConfiguration = .init(),
    interaction: FKRadioButtonInteractionConfiguration = .init(),
    motion: FKSelectionControlMotionConfiguration = .init(),
    accessibility: FKSelectionControlAccessibilityConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.interaction = interaction
    self.motion = motion
    self.accessibility = accessibility
  }
}
