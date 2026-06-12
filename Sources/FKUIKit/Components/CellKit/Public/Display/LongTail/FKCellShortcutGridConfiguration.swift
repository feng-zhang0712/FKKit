import Foundation
public struct FKCellShortcutItem: Sendable, Equatable {
  public var title: String; public var icon: FKCellIconContent
  public init(title: String, icon: FKCellIconContent) { self.title=title; self.icon=icon }
}
public struct FKCellShortcutGridConfiguration: Sendable, Equatable {
  public var items: [FKCellShortcutItem]; public var columns: Int
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(items: [FKCellShortcutItem], columns: Int = 4, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .none, isLastInSection: Bool = true) {
    self.items=items; self.columns=max(1, columns); self.isEnabled=isEnabled
    self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
