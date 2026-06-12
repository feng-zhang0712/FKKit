import Foundation

/// ListKit-friendly row model for ``FKCellInfoCell``.
public struct FKCellInfoRow: Sendable, Equatable, Hashable {
  public var id: String
  public var icon: FKCellIconContent
  public var title: String
  public var subtitles: [String]
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates an info row model.
  public init(
    id: String,
    icon: FKCellIconContent,
    title: String,
    subtitles: [String] = [],
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.id = id
    self.icon = icon
    self.title = title
    self.subtitles = subtitles
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }

  /// Converts to a cell configuration snapshot.
  public var configuration: FKCellInfoConfiguration {
    FKCellInfoConfiguration(
      icon: icon,
      title: title,
      subtitles: subtitles,
      isEnabled: isEnabled,
      separatorPolicy: separatorPolicy,
      isLastInSection: isLastInSection
    )
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
