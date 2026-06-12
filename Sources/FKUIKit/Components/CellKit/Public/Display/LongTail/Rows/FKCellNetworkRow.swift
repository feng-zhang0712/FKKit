import Foundation
public struct FKCellNetworkRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellNetworkConfiguration
  public init(id: String, configuration: FKCellNetworkConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
