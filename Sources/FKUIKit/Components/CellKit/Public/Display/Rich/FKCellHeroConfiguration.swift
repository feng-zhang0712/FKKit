import UIKit

/// Configuration for ``FKCellHeroCell`` (D-06).
public struct FKCellHeroConfiguration: Sendable, Equatable {
  public var icon: FKCellIconContent?
  public var title: String
  public var description: String
  public var textAlignment: NSTextAlignment
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a centered hero card row configuration.
  public init(
    icon: FKCellIconContent? = nil,
    title: String,
    description: String,
    textAlignment: NSTextAlignment = .center,
    separatorPolicy: FKCellSeparatorPolicy = .none,
    isLastInSection: Bool = true
  ) {
    self.icon = icon
    self.title = title
    self.description = description
    self.textAlignment = textAlignment
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
