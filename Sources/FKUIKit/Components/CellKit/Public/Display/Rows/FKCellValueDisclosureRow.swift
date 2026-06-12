import Foundation

/// ListKit-friendly row model for ``FKCellValueDisclosureCell``.
public struct FKCellValueDisclosureRow: Sendable, Equatable, Hashable {
  public var id: String
  public var title: String
  public var value: String
  public var valueNumberOfLines: Int
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a value disclosure row model.
  public init(
    id: String,
    title: String,
    value: String,
    valueNumberOfLines: Int = 1,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.id = id
    self.title = title
    self.value = value
    self.valueNumberOfLines = valueNumberOfLines
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }

  /// Converts to a cell configuration snapshot.
  public var configuration: FKCellValueDisclosureConfiguration {
    FKCellValueDisclosureConfiguration(
      title: title,
      value: value,
      valueNumberOfLines: valueNumberOfLines,
      showsDisclosure: showsDisclosure,
      isEnabled: isEnabled,
      separatorPolicy: separatorPolicy,
      isLastInSection: isLastInSection
    )
  }
}
