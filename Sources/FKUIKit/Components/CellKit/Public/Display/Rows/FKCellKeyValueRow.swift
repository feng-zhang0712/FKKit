import Foundation

/// ListKit-friendly row model for ``FKCellKeyValueCell``.
public struct FKCellKeyValueRow: Sendable, Equatable, Hashable {
  public var id: String
  public var title: String
  public var value: String
  public var valueEmphasis: FKCellValueEmphasis
  public var valueNumberOfLines: Int
  public var isSelectable: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a key-value row model.
  public init(
    id: String,
    title: String,
    value: String,
    valueEmphasis: FKCellValueEmphasis = .secondary,
    valueNumberOfLines: Int = 1,
    isSelectable: Bool = false,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.id = id
    self.title = title
    self.value = value
    self.valueEmphasis = valueEmphasis
    self.valueNumberOfLines = valueNumberOfLines
    self.isSelectable = isSelectable
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }

  /// Converts to a cell configuration snapshot.
  public var configuration: FKCellKeyValueConfiguration {
    FKCellKeyValueConfiguration(
      title: title,
      value: value,
      valueEmphasis: valueEmphasis,
      valueNumberOfLines: valueNumberOfLines,
      isSelectable: isSelectable,
      isEnabled: isEnabled,
      separatorPolicy: separatorPolicy,
      isLastInSection: isLastInSection
    )
  }
}
