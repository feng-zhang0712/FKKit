import Foundation
public struct FKFormCellBiometricRow: Sendable, Equatable, Hashable {
  public var id: String; public var text: String; public var configuration: FKFormCellBiometricConfiguration
  public init(id: String, text: String = "", configuration: FKFormCellBiometricConfiguration) { self.id=id; self.text=text; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
