import Foundation
public struct FKCellSkeletonRowConfiguration: Sendable, Equatable {
  public var lineCount: Int; public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(lineCount: Int = 2, isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .none, isLastInSection: Bool = true) {
    self.lineCount=lineCount; self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
