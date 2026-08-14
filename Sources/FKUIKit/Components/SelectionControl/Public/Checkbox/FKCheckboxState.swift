import Foundation

/// Three-state model for ``FKCheckbox``.
public enum FKCheckboxState: Equatable, Sendable {
  /// Empty box (default).
  case unchecked
  /// Filled with checkmark.
  case checked
  /// Filled with minus (mixed / partial).
  case indeterminate
}
