import Foundation
public struct FKFormCellDragUploadRow: Sendable, Equatable, Hashable {
  public var id: String; public var text: String; public var configuration: FKFormCellDragUploadConfiguration
  public init(id: String, text: String = "", configuration: FKFormCellDragUploadConfiguration) { self.id=id; self.text=text; self.configuration=configuration }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
