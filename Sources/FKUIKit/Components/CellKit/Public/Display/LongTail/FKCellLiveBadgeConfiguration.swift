import Foundation
public struct FKCellLiveBadgeConfiguration: Sendable, Equatable {
  public var title: String; public var liveBadgeText: String
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(title: String, liveBadgeText: String = "LIVE", isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.title=title; self.liveBadgeText=liveBadgeText; self.isEnabled=isEnabled
    self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
