import Foundation
import UIKit

/// ListKit-friendly row model for ``FKCellConversationCell`` (D-20).
public struct FKCellConversationRow: Sendable, Equatable, Hashable {
  public var id: String
  public var imageURL: URL?
  public var image: UIImage?
  public var configuration: FKCellConversationConfiguration

  public init(
    id: String,
    imageURL: URL? = nil,
    image: UIImage? = nil,
    configuration: FKCellConversationConfiguration
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

extension FKCellConversationRow {
  public static func == (lhs: FKCellConversationRow, rhs: FKCellConversationRow) -> Bool {
    lhs.id == rhs.id && lhs.imageURL == rhs.imageURL && lhs.configuration == rhs.configuration
  }
}
