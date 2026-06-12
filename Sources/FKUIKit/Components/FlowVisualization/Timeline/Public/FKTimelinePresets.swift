import UIKit

/// Preset configurations for common timeline scenarios.
public enum FKTimelinePresets {
  /// Logistics tracking with absolute timestamps and current-step emphasis.
  public static func logistics() -> FKTimelineConfiguration {
    var configuration = FKTimelineConfiguration()
    configuration.layout.timestampStyle = .absolute
    configuration.appearance.emphasizesCurrentTitle = true
    configuration.layout.tailStyle = .dotted
    return configuration
  }

  /// Audit log with multi-line captions and read-only interaction.
  public static func auditLog() -> FKTimelineConfiguration {
    var configuration = FKTimelineConfiguration()
    configuration.layout.layout = .embeddedInList
    configuration.layout.captionNumberOfLines = 0
    configuration.appearance.nodeShape = .roundedSquare
    configuration.appearance.density = .compact
    configuration.interaction.allowsSelection = false
    return configuration
  }
}
