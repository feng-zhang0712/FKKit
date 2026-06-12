import Foundation

/// Trailing value color emphasis for key-value rows (D-02, D-16).
public enum FKCellValueEmphasis: Sendable, Equatable {
  /// Secondary label color (default About-style detail).
  case secondary
  /// Primary body color (emphasized values such as storage totals).
  case primary
}
