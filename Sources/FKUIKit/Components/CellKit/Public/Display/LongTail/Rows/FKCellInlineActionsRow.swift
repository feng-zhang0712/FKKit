import Foundation
public struct FKCellInlineActionsRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellInlineActionsConfiguration
  public init(id: String, configuration: FKCellInlineActionsConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
