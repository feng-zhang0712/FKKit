import Foundation
public struct FKCellMonospaceBlockConfiguration: Sendable, Equatable {
  public var codeText: String; public var maxLines: Int; public var showsExpand: Bool
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(codeText: String, maxLines: Int = 4, showsExpand: Bool = true, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.codeText=codeText; self.maxLines=maxLines; self.showsExpand=showsExpand
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
