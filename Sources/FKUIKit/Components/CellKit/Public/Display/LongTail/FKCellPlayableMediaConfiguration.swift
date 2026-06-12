import Foundation
public struct FKCellPlayableMediaConfiguration: Sendable, Equatable {
  public var title: String; public var subtitle: String?; public var cover: FKCellImageContent; public var isNowPlaying: Bool
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, subtitle: String? = nil, cover: FKCellImageContent = .init(), isNowPlaying: Bool = false,
    isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.subtitle=subtitle; self.cover=cover; self.isNowPlaying=isNowPlaying
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
