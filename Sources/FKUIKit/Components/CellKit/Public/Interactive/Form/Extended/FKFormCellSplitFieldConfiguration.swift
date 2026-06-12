import Foundation
public struct FKFormCellSplitFieldConfiguration: Sendable, Equatable {
  public var layout: FKFormCellLayout; public var leftLabel: String?; public var rightLabel: String?
  public var leftText: String; public var rightText: String; public var leftPlaceholder: String?; public var rightPlaceholder: String?
  public var isEnabled: Bool
  public init(layout: FKFormCellLayout = .underline, leftLabel: String? = nil, rightLabel: String? = nil,
    leftText: String = "", rightText: String = "", leftPlaceholder: String? = nil, rightPlaceholder: String? = nil, isEnabled: Bool = true) {
    self.layout=layout; self.leftLabel=leftLabel; self.rightLabel=rightLabel; self.leftText=leftText; self.rightText=rightText
    self.leftPlaceholder=leftPlaceholder; self.rightPlaceholder=rightPlaceholder; self.isEnabled=isEnabled
  }
}
