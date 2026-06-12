import Foundation

/// Configuration for ``FKCellActionCell`` (D-11).
public struct FKCellActionConfiguration: Sendable, Equatable {
  public var title: String
  public var style: FKCellActionStyle
  public var alignment: FKCellActionAlignment
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates an action button row configuration.
  public init(
    title: String,
    style: FKCellActionStyle = .default,
    alignment: FKCellActionAlignment = .leading,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .none,
    isLastInSection: Bool = true
  ) {
    self.title = title
    self.style = style
    self.alignment = alignment
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
