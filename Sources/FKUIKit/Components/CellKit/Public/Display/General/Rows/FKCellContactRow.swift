import Foundation
import UIKit

/// ListKit-friendly row model for ``FKCellContactCell`` (D-18).
public struct FKCellContactRow: Sendable, Equatable, Hashable {
  public var id: String
  public var imageURL: URL?
  public var image: UIImage?
  public var configuration: FKCellContactConfiguration

  public init(
    id: String,
    imageURL: URL? = nil,
    image: UIImage? = nil,
    configuration: FKCellContactConfiguration
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

extension FKCellContactRow {
  public static func == (lhs: FKCellContactRow, rhs: FKCellContactRow) -> Bool {
    lhs.id == rhs.id && lhs.imageURL == rhs.imageURL && lhs.configuration == rhs.configuration
  }
}
