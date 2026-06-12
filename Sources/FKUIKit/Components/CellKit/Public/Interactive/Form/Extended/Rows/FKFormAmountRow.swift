import Foundation
/// Semantic form row preset (F-15).
public struct FKFormAmountRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKFormCellTextFieldConfiguration
  public init(id: String, configuration: FKFormCellTextFieldConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
