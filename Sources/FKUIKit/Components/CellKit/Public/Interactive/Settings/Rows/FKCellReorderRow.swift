import Foundation

/// ListKit-friendly row model for ``FKCellReorderCell``.
public struct FKCellReorderRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellReorderConfiguration

  /// Creates a reorder row model.
  public init(id: String, configuration: FKCellReorderConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
