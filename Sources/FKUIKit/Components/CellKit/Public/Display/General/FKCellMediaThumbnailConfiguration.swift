import Foundation

/// Configuration for ``FKCellMediaThumbnailCell`` (D-23).
public struct FKCellMediaThumbnailConfiguration: Sendable, Equatable {
  public var image: FKCellImageContent
  public var title: String
  public var subtitle: String?
  public var durationBadge: String?
  public var showsDisclosure: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a media thumbnail row configuration.
  public init(
    image: FKCellImageContent = FKCellImageContent(),
    title: String,
    subtitle: String? = nil,
    durationBadge: String? = nil,
    showsDisclosure: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.image = image
    self.title = title
    self.subtitle = subtitle
    self.durationBadge = durationBadge
    self.showsDisclosure = showsDisclosure
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
