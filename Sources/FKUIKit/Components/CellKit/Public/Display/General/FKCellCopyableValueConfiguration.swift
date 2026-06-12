import Foundation

/// Configuration for ``FKCellCopyableValueCell`` (D-39).
public struct FKCellCopyableValueConfiguration: Sendable, Equatable {
  public var label: String
  public var value: String
  public var copyChipConfiguration: FKCopyChipConfiguration?
  public var usesMonospaceValue: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    label: String,
    value: String,
    copyChipConfiguration: FKCopyChipConfiguration? = nil,
    usesMonospaceValue: Bool = false,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.label = label
    self.value = value
    self.copyChipConfiguration = copyChipConfiguration
    self.usesMonospaceValue = usesMonospaceValue
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
