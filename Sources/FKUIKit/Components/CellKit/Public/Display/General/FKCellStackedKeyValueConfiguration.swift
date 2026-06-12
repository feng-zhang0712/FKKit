import Foundation

/// A single title/value pair inside a stacked key-value row (D-29).
public struct FKCellStackedKeyValueEntry: Sendable, Equatable {
  public var title: String
  public var value: String
  public var valueEmphasis: FKCellValueEmphasis

  public init(
    title: String,
    value: String,
    valueEmphasis: FKCellValueEmphasis = .secondary
  ) {
    self.title = title
    self.value = value
    self.valueEmphasis = valueEmphasis
  }
}

/// Configuration for ``FKCellStackedKeyValueCell`` (D-29).
public struct FKCellStackedKeyValueConfiguration: Sendable, Equatable {
  public var entries: [FKCellStackedKeyValueEntry]
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    entries: [FKCellStackedKeyValueEntry],
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.entries = entries
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
