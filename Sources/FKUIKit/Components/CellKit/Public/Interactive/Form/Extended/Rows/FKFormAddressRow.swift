import Foundation
/// Semantic form row preset (F-19).
public struct FKFormAddressRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKFormCellTextFieldConfiguration
  public init(id: String, configuration: FKFormCellTextFieldConfiguration) { self.id=id; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
