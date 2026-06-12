import Foundation
public struct FKCellInlineAction: Sendable, Equatable {
  public var title: String; public var isDestructive: Bool
  public init(title: String, isDestructive: Bool = false) { self.title=title; self.isDestructive=isDestructive }
}
public struct FKCellInlineActionsConfiguration: Sendable, Equatable {
  public var actions: [FKCellInlineAction]; public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(actions: [FKCellInlineAction], isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.actions=actions; self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
