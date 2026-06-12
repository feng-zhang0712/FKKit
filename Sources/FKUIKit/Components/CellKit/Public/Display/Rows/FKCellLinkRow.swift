import Foundation

/// ListKit-friendly row model for ``FKCellLinkCell``.
public struct FKCellLinkRow: Sendable, Equatable, Hashable {
  public var id: String
  public var title: String
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a link row model.
  public init(
    id: String,
    title: String,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.id = id
    self.title = title
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }

  /// Converts to a cell configuration snapshot.
  public var configuration: FKCellLinkConfiguration {
    FKCellLinkConfiguration(
      title: title,
      isEnabled: isEnabled,
      separatorPolicy: separatorPolicy,
      isLastInSection: isLastInSection
    )
  }
}
