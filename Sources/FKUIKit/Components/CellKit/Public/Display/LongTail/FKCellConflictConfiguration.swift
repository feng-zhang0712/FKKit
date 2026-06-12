import Foundation
public struct FKCellConflictConfiguration: Sendable, Equatable {
  public var message: String; public var detail: String?
  public var isEnabled: Bool; public var separatorPolicy: FKCellSeparatorPolicy; public var isLastInSection: Bool
  public init(message: String, detail: String? = nil, isEnabled: Bool = true, separatorPolicy: FKCellSeparatorPolicy = .automatic, isLastInSection: Bool = false) {
    self.message=message; self.detail=detail; self.isEnabled=isEnabled; self.separatorPolicy=separatorPolicy; self.isLastInSection=isLastInSection
  }
}
