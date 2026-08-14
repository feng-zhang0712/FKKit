import Foundation

/// Grouped layout, appearance, interaction, motion, and accessibility for ``FKCheckbox``.
public struct FKCheckboxConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKCheckboxLayoutConfiguration
  public var appearance: FKCheckboxAppearanceConfiguration
  public var interaction: FKCheckboxInteractionConfiguration
  public var motion: FKSelectionControlMotionConfiguration
  public var accessibility: FKSelectionControlAccessibilityConfiguration

  public init(
    layout: FKCheckboxLayoutConfiguration = .init(),
    appearance: FKCheckboxAppearanceConfiguration = .init(),
    interaction: FKCheckboxInteractionConfiguration = .init(),
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
