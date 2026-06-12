import Foundation

/// Configuration for ``FKCellInfoCell`` (D-05).
public struct FKCellInfoConfiguration: Sendable, Equatable {
  public var icon: FKCellIconContent
  public var title: String
  public var subtitles: [String]
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates an app-info style row configuration.
  public init(
    icon: FKCellIconContent,
    title: String,
    subtitles: [String] = [],
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.icon = icon
    self.title = title
    self.subtitles = subtitles
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
