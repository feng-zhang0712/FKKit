import Foundation
public struct FKCellComparisonConfiguration: Sendable, Equatable {
  public var leftTitle: String; public var leftValue: String; public var rightTitle: String; public var rightValue: String
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(leftTitle: String, leftValue: String, rightTitle: String, rightValue: String, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.leftTitle=leftTitle; self.leftValue=leftValue; self.rightTitle=rightTitle; self.rightValue=rightValue
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
