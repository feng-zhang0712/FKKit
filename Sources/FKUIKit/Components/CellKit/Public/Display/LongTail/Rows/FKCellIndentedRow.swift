import Foundation
public struct FKCellIndentedRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellIndentedConfiguration
  public init(id: String, configuration: FKCellIndentedConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
