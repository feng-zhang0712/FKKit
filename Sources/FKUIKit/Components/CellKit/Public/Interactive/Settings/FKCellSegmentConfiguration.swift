import Foundation
public struct FKCellSegmentConfiguration: Sendable, Equatable {
  public var segments: [String]; public var selectedIndex: Int; public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(segments: [String], selectedIndex: Int = 0, isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.segments=segments; self.selectedIndex=selectedIndex; self.isEnabled=isEnabled
    self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
