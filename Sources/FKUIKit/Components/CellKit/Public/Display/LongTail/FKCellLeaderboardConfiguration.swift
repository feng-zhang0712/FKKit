import Foundation
public struct FKCellLeaderboardConfiguration: Sendable, Equatable {
  public var rank: Int; public var name: String; public var scoreText: String; public var avatarConfiguration: FKAvatarConfiguration
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(rank: Int, name: String, scoreText: String, avatarConfiguration: FKAvatarConfiguration = .init(),
    isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.rank=rank; self.name=name; self.scoreText=scoreText; self.avatarConfiguration=avatarConfiguration
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
