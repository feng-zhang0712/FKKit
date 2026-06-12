import Foundation
public struct FKCellNowPlayingConfiguration: Sendable, Equatable {
  public var title: String; public var artist: String?; public var cover: FKCellImageContent; public var isPlaying: Bool
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, artist: String? = nil, cover: FKCellImageContent = .init(), isPlaying: Bool = false,
    isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.artist=artist; self.cover=cover; self.isPlaying=isPlaying
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
