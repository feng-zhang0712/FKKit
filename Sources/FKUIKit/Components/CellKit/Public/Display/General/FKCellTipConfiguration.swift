import Foundation

/// Configuration for ``FKCellTipCell`` (D-57).
public struct FKCellTipConfiguration: Sendable, Equatable {
  public var text: String
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    text: String,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.text = text
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
