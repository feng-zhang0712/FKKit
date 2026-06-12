import UIKit

/// Preset configurations for common step indicator scenarios.
public enum FKStepIndicatorPresets {
  /// Read-only checkout header with labels below nodes.
  public static func checkout() -> FKStepIndicatorConfiguration {
    var configuration = FKStepIndicatorConfiguration()
    configuration.interaction.allowsSelection = false
    configuration.layout.titleNumberOfLines = 1
    configuration.appearance.emphasizesCurrentTitle = true
    return configuration
  }

  /// Compact onboarding header with tappable completed steps.
  public static func onboarding() -> FKStepIndicatorConfiguration {
    var configuration = FKStepIndicatorConfiguration()
    configuration.layout.layout = .compactDots
    configuration.appearance.density = .compact
    configuration.appearance.nodeSize = .small
    configuration.interaction.allowsSelection = true
    configuration.interaction.selectableStates = [.completed]
    configuration.interaction.hapticOnSelect = true
    return configuration
  }
}
