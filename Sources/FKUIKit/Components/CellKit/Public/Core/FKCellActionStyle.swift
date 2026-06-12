import Foundation

/// Visual style for action rows (D-11).
public enum FKCellActionStyle: Sendable, Equatable {
  case `default`
  case destructive
}

/// Horizontal alignment for action row titles (D-11).
public enum FKCellActionAlignment: Sendable, Equatable {
  case leading
  case center
}
