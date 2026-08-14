import UIKit

/// Convenience factories for common ``FKCheckbox`` configurations.
@MainActor
public enum FKCheckboxPresets {
  /// Settings-style row with trailing label placement and medium indicator.
  public static func settingsRow() -> FKCheckboxConfiguration {
    var configuration = FKCheckboxConfiguration()
    configuration.layout.labelPlacement = .trailing
    configuration.layout.indicatorEdge = .leading
    configuration.layout.size = .medium
    return configuration
  }

  /// Indicator-only control suitable for custom table cells.
  public static func indicatorOnly(size: FKSelectionControlSize = .medium) -> FKCheckboxConfiguration {
    var configuration = FKCheckboxConfiguration()
    configuration.layout.size = size
    configuration.layout.labelPlacement = .hidden
    configuration.layout.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    return configuration
  }

  /// Multi-line agreement row with body-aligned medium indicator.
  public static func agreement() -> FKCheckboxConfiguration {
    var configuration = FKCheckboxConfiguration()
    configuration.layout.size = .medium
    configuration.layout.labelPlacement = .trailing
    configuration.layout.titleNumberOfLines = 0
    configuration.layout.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    return configuration
  }
}
