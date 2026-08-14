import UIKit

/// Preset or custom tint applied to checked / selected / indeterminate indicators.
public enum FKSelectionControlTint: Equatable, @unchecked Sendable {
  /// Brand / general accent (default).
  case blue
  /// Success or affirmative emphasis.
  case green
  /// Emphasis or risk-related options.
  case red
  /// Warning-related options.
  case orange
  /// Brand extension.
  case purple
  /// Host-provided color (prefer dynamic colors for Dark Mode).
  case custom(UIColor)
}
