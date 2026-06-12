import Foundation
public struct FKCellStepperConfiguration: Sendable, Equatable {
  public var title: String; public var value: Double; public var minimumValue: Double; public var maximumValue: Double; public var stepValue: Double
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, value: Double, minimumValue: Double = 0, maximumValue: Double = 100, stepValue: Double = 1,
    isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.value=value; self.minimumValue=minimumValue; self.maximumValue=maximumValue; self.stepValue=stepValue
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
