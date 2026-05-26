import UIKit

/// Built-in appearance presets for common action sheet chrome styles.
public enum FKActionSheetAppearancePreset: Sendable, Equatable {
  /// System-like flat full-width rows on a plain table.
  case system
  /// Rounded card groups on a dimmed sheet background.
  case card
  /// Minimal separators with a flat background.
  case plain
}

public extension FKActionSheetAppearance {
  /// Builds an appearance value for a preset.
  static func preset(_ preset: FKActionSheetAppearancePreset) -> FKActionSheetAppearance {
    switch preset {
    case .system:
      return .default
    case .card:
      var appearance = FKActionSheetAppearance.default
      appearance.backgroundColor = .systemGroupedBackground
      appearance.cellBackgroundColor = .secondarySystemGroupedBackground
      appearance.rowAlignment = .center
      return appearance
    case .plain:
      var appearance = FKActionSheetAppearance.default
      appearance.backgroundColor = .systemBackground
      appearance.cellBackgroundColor = .systemBackground
      appearance.separatorStyle = .singleLine
      appearance.rowAlignment = .leading
      return appearance
    }
  }
}
