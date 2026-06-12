import UIKit

/// ListKit-friendly row model for ``FKCellProfileCell`` (D-17).
public struct FKCellProfileRow: Sendable, Equatable, Hashable {
  public var id: String
  public var imageURL: URL?
  public var image: UIImage?
  public var displayName: String?
  public var configuration: FKCellProfileConfiguration

  /// Creates a profile row model.
  public init(
    id: String,
    imageURL: URL? = nil,
    image: UIImage? = nil,
    displayName: String? = nil,
    configuration: FKCellProfileConfiguration
  ) {
    self.id = id
    self.imageURL = imageURL
    self.image = image
    self.displayName = displayName
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension FKCellProfileRow {
  public static func == (lhs: FKCellProfileRow, rhs: FKCellProfileRow) -> Bool {
    lhs.id == rhs.id
      && lhs.imageURL == rhs.imageURL
      && lhs.displayName == rhs.displayName
      && lhs.configuration == rhs.configuration
  }
}
