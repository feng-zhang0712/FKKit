import Foundation
public struct FKCellSubscriptionPlanConfiguration: Sendable, Equatable {
  public var planName: String; public var priceText: String; public var features: [String]; public var isSelected: Bool
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(planName: String, priceText: String, features: [String] = [], isSelected: Bool = false, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.planName=planName; self.priceText=priceText; self.features=features; self.isSelected=isSelected
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
