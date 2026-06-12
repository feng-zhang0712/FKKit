import Foundation

/// Configuration for ``FKCellAudioTrackCell`` (D-24).
public struct FKCellAudioTrackConfiguration: Sendable, Equatable {
  public var cover: FKCellImageContent
  public var title: String
  public var artist: String?
  public var duration: String?
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    cover: FKCellImageContent = FKCellImageContent(),
    title: String,
    artist: String? = nil,
    duration: String? = nil,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.cover = cover
    self.title = title
    self.artist = artist
    self.duration = duration
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
