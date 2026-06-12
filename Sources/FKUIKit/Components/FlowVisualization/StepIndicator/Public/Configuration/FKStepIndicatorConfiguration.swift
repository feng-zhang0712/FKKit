import UIKit

/// Grouped settings for ``FKStepIndicator``.
public struct FKStepIndicatorConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKStepIndicatorLayoutConfiguration
  public var appearance: FKFlowAppearanceConfiguration
  public var interaction: FKFlowInteractionConfiguration
  public var motion: FKFlowMotionConfiguration
  public var accessibility: FKFlowAccessibilityConfiguration

  public init(
    layout: FKStepIndicatorLayoutConfiguration = .init(),
    appearance: FKFlowAppearanceConfiguration = .init(),
    interaction: FKFlowInteractionConfiguration = .init(),
    motion: FKFlowMotionConfiguration = .init(),
    accessibility: FKFlowAccessibilityConfiguration = .init()
  ) {
    self.layout = layout
    self.appearance = appearance
    self.interaction = interaction
    self.motion = motion
    self.accessibility = accessibility
  }
}

// MARK: - Global defaults

/// Namespace for shared defaults applied to new ``FKStepIndicator`` instances.
@MainActor
public enum FKStepIndicatorDefaults {
  /// Baseline copied at initialization until the host replaces ``FKStepIndicator/configuration``.
  public static var configuration = FKStepIndicatorConfiguration()
}
