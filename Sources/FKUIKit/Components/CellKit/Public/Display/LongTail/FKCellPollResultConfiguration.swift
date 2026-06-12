import Foundation
public struct FKCellPollResultConfiguration: Sendable, Equatable {
  public var optionTitle: String; public var percent: Double; public var percentText: String?
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(optionTitle: String, percent: Double, percentText: String? = nil, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.optionTitle=optionTitle; self.percent=percent; self.percentText=percentText
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
