import Foundation

/// ListKit-friendly row model for ``FKCellMediaThumbnailCell`` (D-23).
public struct FKCellMediaThumbnailRow: Sendable, Equatable, Hashable {
  public var id: String
  public var configuration: FKCellMediaThumbnailConfiguration

  public init(id: String, configuration: FKCellMediaThumbnailConfiguration) {
    self.id = id
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
