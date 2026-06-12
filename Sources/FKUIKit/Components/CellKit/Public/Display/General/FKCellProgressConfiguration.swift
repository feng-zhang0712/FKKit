import Foundation

/// Configuration for ``FKCellProgressCell`` (D-35).
public struct FKCellProgressConfiguration: Sendable, Equatable {
  public var leadingIcon: FKCellIconContent?
  public var title: String
  public var progress: CGFloat
  public var percentText: String?
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    leadingIcon: FKCellIconContent? = nil,
    title: String,
    progress: CGFloat = 0,
    percentText: String? = nil,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.leadingIcon = leadingIcon
    self.title = title
    self.progress = min(1, max(0, progress))
    self.percentText = percentText
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
