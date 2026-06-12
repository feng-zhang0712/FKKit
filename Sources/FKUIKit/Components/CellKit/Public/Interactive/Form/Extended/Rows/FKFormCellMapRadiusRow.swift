import Foundation

/// ListKit-friendly row model for ``FKFormCellMapRadiusCell``.
public struct FKFormCellMapRadiusRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKFormCellMapRadiusConfiguration
  public var radiusMeters: Double

  public init(
    id: String,
    configuration: FKFormCellMapRadiusConfiguration,
    radiusMeters: Double = 1000
  ) {
    self.id = id
    self.configuration = configuration
    self.radiusMeters = radiusMeters
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
