import Foundation

/// Configuration for ``FKCellSelectionCell`` (I-03, I-07).
public struct FKCellSelectionConfiguration: Sendable, Equatable {
  public var title: String
  public var subtitle: String?
  public var isSelected: Bool
  public var selectionMode: FKCellSelectionMode
  public var reservesLeadingSpaceWhenUnselected: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a checkmark selection row configuration.
  public init(
    title: String,
    subtitle: String? = nil,
    isSelected: Bool = false,
    selectionMode: FKCellSelectionMode = .single,
    reservesLeadingSpaceWhenUnselected: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.title = title
    self.subtitle = subtitle
    self.isSelected = isSelected
    self.selectionMode = selectionMode
    self.reservesLeadingSpaceWhenUnselected = reservesLeadingSpaceWhenUnselected
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }
}
