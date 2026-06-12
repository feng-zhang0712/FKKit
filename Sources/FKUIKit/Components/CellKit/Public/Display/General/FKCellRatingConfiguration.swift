import Foundation

/// Configuration for ``FKCellRatingCell`` (D-52).
public struct FKCellRatingConfiguration: Sendable, Equatable {
  public var rating: Double
  public var maxRating: Int
  public var reviewCountText: String?
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    rating: Double,
    maxRating: Int = 5,
    reviewCountText: String? = nil,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.rating = rating
    self.maxRating = max(1, maxRating)
    self.reviewCountText = reviewCountText
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
