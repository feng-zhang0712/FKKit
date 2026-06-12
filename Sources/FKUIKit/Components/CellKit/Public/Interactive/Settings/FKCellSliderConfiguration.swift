import Foundation
public struct FKCellSliderConfiguration: Sendable, Equatable {
  public var title: String; public var value: Float; public var minimumValue: Float; public var maximumValue: Float
  public var valueText: String?; public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, value: Float, minimumValue: Float = 0, maximumValue: Float = 1, valueText: String? = nil,
    isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.value=value; self.minimumValue=minimumValue; self.maximumValue=maximumValue
    self.valueText=valueText; self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
