import Foundation
public struct FKCellEditingRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellEditingConfiguration
  public init(id: String, configuration: FKCellEditingConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
