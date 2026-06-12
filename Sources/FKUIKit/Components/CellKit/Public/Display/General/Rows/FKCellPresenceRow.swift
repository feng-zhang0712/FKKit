import Foundation
import UIKit

/// ListKit-friendly row model for ``FKCellPresenceCell`` (D-19).
public struct FKCellPresenceRow: Sendable, Equatable, Hashable {
  public var id: String
  public var imageURL: URL?
  public var image: UIImage?
  public var configuration: FKCellPresenceConfiguration

  public init(
    id: String,
    imageURL: URL? = nil,
    image: UIImage? = nil,
    configuration: FKCellPresenceConfiguration
  ) {
    self.id = id
    self.imageURL = imageURL
    self.image = image
    self.configuration = configuration
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

extension FKCellPresenceRow {
  public static func == (lhs: FKCellPresenceRow, rhs: FKCellPresenceRow) -> Bool {
    lhs.id == rhs.id && lhs.imageURL == rhs.imageURL && lhs.configuration == rhs.configuration
  }
}
