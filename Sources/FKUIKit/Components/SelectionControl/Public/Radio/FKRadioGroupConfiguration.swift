import Foundation

/// Grouped configuration for ``FKRadioGroup``.
public struct FKRadioGroupConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKRadioGroupLayoutConfiguration
  public var appearance: FKRadioGroupAppearanceConfiguration
  public var interaction: FKRadioGroupInteractionConfiguration
  public var motion: FKSelectionControlMotionConfiguration
  public var accessibility: FKSelectionControlAccessibilityConfiguration

  public init(
    layout: FKRadioGroupLayoutConfiguration = .init(),
    appearance: FKRadioGroupAppearanceConfiguration = .init(),
    interaction: FKRadioGroupInteractionConfiguration = .init(),
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
