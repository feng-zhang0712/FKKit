import Foundation

/// Configuration for ``FKCellExpandableCell`` (D-64, D-65).
public struct FKCellExpandableConfiguration: Sendable, Equatable {
  public var title: String
  public var body: String?
  public var isExpanded: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    title: String,
    body: String? = nil,
    isExpanded: Bool = false,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.body = body
    self.isExpanded = isExpanded
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
