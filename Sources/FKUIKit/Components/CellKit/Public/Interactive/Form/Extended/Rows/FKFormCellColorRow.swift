import Foundation
public struct FKFormCellColorRow: Sendable, Equatable, Hashable {
  public var id: String; public var text: String; public var configuration: FKFormCellColorConfiguration
  public init(id: String, text: String = "", configuration: FKFormCellColorConfiguration) { self.id=id; self.text=text; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
