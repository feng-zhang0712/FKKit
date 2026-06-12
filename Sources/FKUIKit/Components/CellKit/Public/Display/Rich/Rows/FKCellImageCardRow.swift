import Foundation

/// ListKit-friendly row model for ``FKCellImageCardCell``.
public struct FKCellImageCardRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellImageCardConfiguration

  /// Creates an image card row model.
  public init(id: String, configuration: FKCellImageCardConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
