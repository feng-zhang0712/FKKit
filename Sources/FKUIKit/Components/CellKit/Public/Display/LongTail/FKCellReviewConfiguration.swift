import Foundation
public struct FKCellReviewConfiguration: Sendable, Equatable {
  public var authorName: String
  public var excerpt: String
  public var rating: Double
  public var maxRating: Int
  public var timestamp: String?
  public var avatarConfiguration: FKAvatarConfiguration
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool
  public init(authorName: String, excerpt: String, rating: Double, maxRating: Int = 5,
    timestamp: String? = nil, avatarConfiguration: FKAvatarConfiguration = .init(),
    isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false) {
    self.authorName = authorName; self.excerpt = excerpt; self.rating = rating
    self.maxRating = maxRating; self.timestamp = timestamp
    self.avatarConfiguration = avatarConfiguration; self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy; self.isLastInSection = isLastInSection
  }
}
