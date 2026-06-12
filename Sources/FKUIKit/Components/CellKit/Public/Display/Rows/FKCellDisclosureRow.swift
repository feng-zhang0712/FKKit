import Foundation

/// ListKit-friendly row model for ``FKCellDisclosureCell``.
public struct FKCellDisclosureRow: Sendable, Equatable, Hashable {
  public var id: String
  public var title: String
  public var isEnabled: Bool
  public var showsDisclosure: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a disclosure row model.
  public init(
    id: String,
    title: String,
    isEnabled: Bool = true,
    showsDisclosure: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.id = id
    self.title = title
    self.isEnabled = isEnabled
    self.showsDisclosure = showsDisclosure
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}

extension FKCellDisclosureRow {
  /// Converts to a cell configuration snapshot.
  public var configuration: FKCellDisclosureConfiguration {
    FKCellDisclosureConfiguration(
      title: title,
      isEnabled: isEnabled,
      showsDisclosure: showsDisclosure,
      separatorPolicy: separatorPolicy,
      isLastInSection: isLastInSection
    )
  }
}
