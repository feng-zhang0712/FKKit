import Foundation

/// Configuration for ``FKCellKeyValueCell`` (D-02, D-16).
public struct FKCellKeyValueConfiguration: Sendable, Equatable {
  public var title: String
  public var value: String
  public var valueEmphasis: FKCellValueEmphasis
  public var valueNumberOfLines: Int
  public var isSelectable: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a read-only key-value row configuration.
  public init(
    title: String,
    value: String,
    valueEmphasis: FKCellValueEmphasis = .secondary,
    valueNumberOfLines: Int = 1,
    isSelectable: Bool = false,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.value = value
    self.valueEmphasis = valueEmphasis
    self.valueNumberOfLines = valueNumberOfLines
    self.isSelectable = isSelectable
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
