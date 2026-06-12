import Foundation

/// Configuration for ``FKCellThumbnailStripCell`` (D-26).
public struct FKCellThumbnailStripConfiguration: Sendable, Equatable {
  public var thumbnails: [FKCellImageContent]
  public var itemSize: CGFloat
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a horizontal thumbnail strip configuration.
  public init(
    thumbnails: [FKCellImageContent],
    itemSize: CGFloat = 72,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.thumbnails = thumbnails
    self.itemSize = itemSize
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
