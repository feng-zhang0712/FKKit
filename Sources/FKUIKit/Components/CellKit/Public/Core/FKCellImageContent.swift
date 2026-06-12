import UIKit

/// Remote or local image payload for feed and commerce display rows.
public struct FKCellImageContent: @unchecked Sendable, Equatable {
  public var url: URL?
  public var image: UIImage?

  /// Creates image content for ``FKImageView``-backed slots.
  public init(url: URL? = nil, image: UIImage? = nil) {
    self.url = url
    self.image = image
  }
}

extension FKCellImageContent {
  public static func == (lhs: FKCellImageContent, rhs: FKCellImageContent) -> Bool {
    lhs.url == rhs.url && lhs.image === rhs.image
  }
}
