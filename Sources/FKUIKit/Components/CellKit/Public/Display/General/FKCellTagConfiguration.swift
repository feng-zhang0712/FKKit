import Foundation

/// Configuration for ``FKCellTagCell`` (D-54).
public struct FKCellTagConfiguration: Sendable, Equatable {
  public var title: String?
  public var chipLabels: [String]
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  public init(
    title: String? = nil,
    chipLabels: [String] = [],
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.chipLabels = chipLabels
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
