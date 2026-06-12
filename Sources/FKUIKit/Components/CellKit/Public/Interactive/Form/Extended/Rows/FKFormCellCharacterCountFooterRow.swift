import Foundation
public struct FKFormCellCharacterCountFooterRow: Sendable, Equatable, Hashable {
  public var id: String; public var text: String; public var configuration: FKFormCellCharacterCountFooterConfiguration
  public init(id: String, text: String = "", configuration: FKFormCellCharacterCountFooterConfiguration) { self.id=id; self.text=text; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
