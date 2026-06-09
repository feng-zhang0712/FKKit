import UIKit

/// Grouped settings for ``FKTimeline``.
public struct FKTimelineConfiguration: @unchecked Sendable, Equatable {
  public var layout: FKTimelineLayoutConfiguration
  public var appearance: FKFlowAppearanceConfiguration
  public var interaction: FKFlowInteractionConfiguration
  public var motion: FKFlowMotionConfiguration
  public var accessibility: FKFlowAccessibilityConfiguration

  public init(
    layout: FKTimelineLayoutConfiguration = .init(),
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

/// Namespace for shared defaults applied to new ``FKTimeline`` instances.
@MainActor
public enum FKTimelineDefaults {
  /// Baseline copied at initialization until the host replaces ``FKTimeline/configuration``.
  public static var configuration = FKTimelineConfiguration()
}
