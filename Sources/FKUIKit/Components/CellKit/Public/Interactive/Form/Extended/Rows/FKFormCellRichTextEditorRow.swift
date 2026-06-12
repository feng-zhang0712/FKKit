import Foundation
public struct FKFormCellRichTextEditorRow: Sendable, Equatable, Hashable {
  public var id: String; public var text: String; public var configuration: FKFormCellRichTextEditorConfiguration
  public init(id: String, text: String = "", configuration: FKFormCellRichTextEditorConfiguration) { self.id=id; self.text=text; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
