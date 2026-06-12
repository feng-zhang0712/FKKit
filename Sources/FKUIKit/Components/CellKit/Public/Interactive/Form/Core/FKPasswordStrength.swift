import Foundation

/// Optional password strength indicator for validation presentation (X-25).
public enum FKPasswordStrength: Sendable, Equatable {
  case weak
  case medium
  case strong
}
