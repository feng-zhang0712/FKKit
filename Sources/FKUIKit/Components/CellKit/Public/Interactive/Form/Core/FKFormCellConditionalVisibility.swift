import Foundation
/// Helper for linkage-driven field visibility (X-41).
public struct FKFormCellConditionalVisibility: Sendable, Equatable {
  public var linkageID: FKFormCellLinkageID
  public var isVisible: Bool
  public init(linkageID: FKFormCellLinkageID, isVisible: Bool) {
    self.linkageID = linkageID; self.isVisible = isVisible
  }
  public func shouldShow(when sourceValue: String, equals expected: String) -> Bool {
    isVisible && sourceValue == expected
  }
}
