import Foundation

/// Configuration for ``FKCellFeatureCardCell`` (D-12).
public struct FKCellFeatureCardConfiguration: Sendable, Equatable {
  public var icon: FKCellIconContent?
  public var title: String
  public var description: String
  public var primaryAction: FKCellActionLink
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a feature card with hero content and footer CTA.
  public init(
    icon: FKCellIconContent? = nil,
    title: String,
    description: String,
    primaryAction: FKCellActionLink,
    separatorPolicy: FKCellSeparatorPolicy = .none,
    isLastInSection: Bool = true
  ) {
    self.icon = icon
    self.title = title
    self.description = description
    self.primaryAction = primaryAction
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
