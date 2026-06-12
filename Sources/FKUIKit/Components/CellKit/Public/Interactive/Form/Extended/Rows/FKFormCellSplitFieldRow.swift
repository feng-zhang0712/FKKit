import Foundation
public struct FKFormCellSplitFieldRow: Sendable, Equatable, Hashable {
  public var id: String; public var leftText: String; public var rightText: String; public var configuration: FKFormCellSplitFieldConfiguration
  public init(id: String, leftText: String = "", rightText: String = "", configuration: FKFormCellSplitFieldConfiguration) {
    self.id=id; self.leftText=leftText; self.rightText=rightText; self.configuration=configuration
  }
  public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
