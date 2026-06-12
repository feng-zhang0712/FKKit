import Foundation

/// Configuration for ``FKCellFilterSummaryCell`` (D-55).
public struct FKCellFilterSummaryConfiguration: Sendable, Equatable {
  public var chipLabels: [String]
  public var clearButtonTitle: String
  public var showsClearButton: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    chipLabels: [String] = [],
    clearButtonTitle: String = "Clear",
    showsClearButton: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.chipLabels = chipLabels
    self.clearButtonTitle = clearButtonTitle
    self.showsClearButton = showsClearButton
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
