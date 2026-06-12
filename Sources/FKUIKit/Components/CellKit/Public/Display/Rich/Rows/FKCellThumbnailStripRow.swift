import Foundation

/// ListKit-friendly row model for ``FKCellThumbnailStripCell``.
public struct FKCellThumbnailStripRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellThumbnailStripConfiguration

  /// Creates a thumbnail strip row model.
  public init(id: String, configuration: FKCellThumbnailStripConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
