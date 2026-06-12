import Foundation
public struct FKCellFavoriteRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellFavoriteConfiguration
  public init(id: String, configuration: FKCellFavoriteConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
