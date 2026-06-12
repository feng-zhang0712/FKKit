import Foundation
import UIKit
public struct FKCellReviewRow: Sendable, Equatable, Hashable {
  public var id: String; public var configuration: FKCellReviewConfiguration
  public var imageURL: URL?; public var image: UIImage?
  public init(id: String, configuration: FKCellReviewConfiguration, imageURL: URL? = nil, image: UIImage? = nil) {
    self.id = id; self.configuration = configuration; self.imageURL = imageURL; self.image = image
  }
  public func hash(into hasher: inout Hasher) { hasher.combine(id); hasher.combine(image) }
}
