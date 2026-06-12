import Foundation

/// Configuration for ``FKCellLinkCell`` (D-10).
public struct FKCellLinkConfiguration: Sendable, Equatable {
  public var title: String
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a tappable link-style row configuration.
  public init(
    title: String,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
