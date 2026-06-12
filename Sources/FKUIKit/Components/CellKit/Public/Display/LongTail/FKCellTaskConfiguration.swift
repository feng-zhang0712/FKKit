import Foundation
public struct FKCellTaskConfiguration: Sendable, Equatable {
  public var title: String; public var dueDateText: String?; public var isCompleted: Bool; public var isOverdue: Bool
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, dueDateText: String? = nil, isCompleted: Bool = false, isOverdue: Bool = false,
    isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.dueDateText=dueDateText; self.isCompleted=isCompleted; self.isOverdue=isOverdue
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
