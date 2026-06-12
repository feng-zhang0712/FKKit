import Foundation

/// Configuration for ``FKCellArticleCell`` (D-25).
public struct FKCellArticleConfiguration: Sendable, Equatable {
  public var thumbnail: FKCellImageContent?
  public var title: String
  public var source: String?
  public var timestamp: String?
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    thumbnail: FKCellImageContent? = nil,
    title: String,
    source: String? = nil,
    timestamp: String? = nil,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.thumbnail = thumbnail
    self.title = title
    self.source = source
    self.timestamp = timestamp
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
