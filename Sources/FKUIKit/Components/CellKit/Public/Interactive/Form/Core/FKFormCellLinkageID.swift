import Foundation

/// Identifier for cross-field linkage orchestrated by the host (X-41, X-42).
public struct FKFormCellLinkageID: Hashable, Sendable, Equatable {
  public let rawValue: String

  /// Creates a linkage identifier.
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}
