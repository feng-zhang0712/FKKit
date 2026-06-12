import Foundation

/// ListKit-friendly row model for ``FKCellHeroCell``.
public struct FKCellHeroRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellHeroConfiguration

  /// Creates a hero row model.
  public init(id: String, configuration: FKCellHeroConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
