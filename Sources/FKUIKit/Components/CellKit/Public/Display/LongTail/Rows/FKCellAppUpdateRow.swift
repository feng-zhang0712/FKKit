import Foundation
public struct FKCellAppUpdateRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellAppUpdateConfiguration
  public init(id: String, configuration: FKCellAppUpdateConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
