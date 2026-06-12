import Foundation

/// ListKit-friendly row model for ``FKCellStorageSummaryCell``.
public struct FKCellStorageSummaryRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellStorageSummaryConfiguration

  /// Creates a storage summary row model.
  public init(id: String, configuration: FKCellStorageSummaryConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
