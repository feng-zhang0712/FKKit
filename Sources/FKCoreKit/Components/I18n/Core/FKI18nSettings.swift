import Foundation

/// Process-wide defaults for ``FKI18nManager`` and related helpers.
public enum FKI18nSettings {
  /// Default configuration applied when creating managers without an explicit ``FKI18nConfiguration``.
  nonisolated(unsafe) public static var defaultConfiguration: FKI18nConfiguration = .default
}
