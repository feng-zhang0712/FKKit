import Foundation
public struct FKFormCellVoiceInputRow: Sendable, Equatable, Hashable {
  public var id: String; public var text: String; public var configuration: FKFormCellVoiceInputConfiguration
  public init(id: String, text: String = "", configuration: FKFormCellVoiceInputConfiguration) { self.id=id; self.text=text; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
