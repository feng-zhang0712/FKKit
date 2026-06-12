import Foundation
public struct FKCellAppUpdateConfiguration: Sendable, Equatable {
  public var versionText: String; public var releaseNotes: String?; public var showsUpdateBadge: Bool
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(versionText: String, releaseNotes: String? = nil, showsUpdateBadge: Bool = true, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.versionText=versionText; self.releaseNotes=releaseNotes; self.showsUpdateBadge=showsUpdateBadge
    self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
