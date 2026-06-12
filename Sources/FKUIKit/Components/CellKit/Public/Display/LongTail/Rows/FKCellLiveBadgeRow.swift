import Foundation
public struct FKCellLiveBadgeRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellLiveBadgeConfiguration
  public init(id: String, configuration: FKCellLiveBadgeConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
