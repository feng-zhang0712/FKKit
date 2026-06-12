import Foundation
public struct FKFormCellSettingsLinkRow: Sendable, Equatable, Hashable {
  public var id: String; public var text: String; public var configuration: FKFormCellSettingsLinkConfiguration
  public init(id: String, text: String = "", configuration: FKFormCellSettingsLinkConfiguration) { self.id=id; self.text=text; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
