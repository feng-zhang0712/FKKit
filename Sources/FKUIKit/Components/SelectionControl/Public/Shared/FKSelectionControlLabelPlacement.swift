import Foundation

/// Whether and where the title / subtitle block is shown relative to the indicator.
public enum FKSelectionControlLabelPlacement: Sendable, Equatable {
  /// Title follows the indicator along the reading direction (default for design-aligned rows).
  case trailing
  /// Title precedes the indicator along the reading direction.
  case leading
  /// Indicator only; no title or subtitle.
  case hidden
}
