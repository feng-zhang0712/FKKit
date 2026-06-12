import Foundation

/// ListKit-friendly row model for ``FKCellFeatureCardCell``.
public struct FKCellFeatureCardRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellFeatureCardConfiguration

  /// Creates a feature card row model.
  public init(id: String, configuration: FKCellFeatureCardConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
