import Foundation

/// Configuration for ``FKCellReorderCell`` (I-06).
public struct FKCellReorderConfiguration: Sendable, Equatable {
  public var title: String
  public var subtitle: String?
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a reorder row configuration.
  public init(
    title: String,
    subtitle: String? = nil,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.subtitle = subtitle
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
