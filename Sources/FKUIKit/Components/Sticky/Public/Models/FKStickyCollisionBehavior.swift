import Foundation

/// How multiple stuck targets interact along the pin edge.
public enum FKStickyCollisionBehavior: String, Sendable, Equatable, CaseIterable {
  /// Later targets push earlier stuck targets off the pin line (section-header style). Default.
  case pushOff
  /// Multiple targets remain stuck simultaneously, stacked along the pin edge (filter + tabs).
  case stack
}
