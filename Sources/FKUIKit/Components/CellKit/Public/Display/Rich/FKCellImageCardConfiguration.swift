import Foundation

/// Configuration for ``FKCellImageCardCell`` (D-27).
public struct FKCellImageCardConfiguration: Sendable, Equatable {
  public var image: FKCellImageContent
  public var title: String
  public var summary: String
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a 16:9 image card configuration.
  public init(
    image: FKCellImageContent,
    title: String,
    summary: String,
    separatorPolicy: FKCellSeparatorPolicy = .none,
    isLastInSection: Bool = true
  ) {
    self.image = image
    self.title = title
    self.summary = summary
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
