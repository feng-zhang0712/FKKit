import Foundation

/// Visual layout archetype shared by text-style form cells (X-01–X-05).
public enum FKFormCellLayout: Sendable, Equatable {
  /// Material-style label above input with full-width underline (X-01, R-01).
  case underline
  /// Rounded card with label stacked above the field (X-02, R-04).
  case cardStacked
  /// Single-line value inside a rounded card (X-03, R-02).
  case cardInline
  /// Fixed-width leading label with trailing field (X-04, R-07).
  case inlineLabel
  /// Leading icon with underline field (X-05, R-05).
  case iconUnderline
  /// Inset grouped card containing an inline-label field.
  case groupedInset
  /// Split country code and phone number fields with a vertical divider (X-06, R-04).
  case cardSplit
}
