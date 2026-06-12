import Foundation

/// ListKit-friendly row model for ``FKCellSelectionCell``.
public struct FKCellSelectionRow: Sendable, Equatable, Hashable {
  public var id: String
  public var title: String
  public var subtitle: String?
  public var isSelected: Bool
  public var selectionMode: FKCellSelectionMode
  public var reservesLeadingSpaceWhenUnselected: Bool
  public var isEnabled: Bool
  public var separatorPolicy: FKCellSeparatorPolicy
  public var isLastInSection: Bool

  /// Creates a selection row model.
  public init(
    id: String,
    title: String,
    subtitle: String? = nil,
    isSelected: Bool = false,
    selectionMode: FKCellSelectionMode = .single,
    reservesLeadingSpaceWhenUnselected: Bool = true,
    isEnabled: Bool = true,
    separatorPolicy: FKCellSeparatorPolicy = .automatic,
    isLastInSection: Bool = false
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.isSelected = isSelected
    self.selectionMode = selectionMode
    self.reservesLeadingSpaceWhenUnselected = reservesLeadingSpaceWhenUnselected
    self.isEnabled = isEnabled
    self.separatorPolicy = separatorPolicy
    self.isLastInSection = isLastInSection
  }

  /// Converts to a cell configuration snapshot.
  public var configuration: FKCellSelectionConfiguration {
    FKCellSelectionConfiguration(
      title: title,
      subtitle: subtitle,
      isSelected: isSelected,
      selectionMode: selectionMode,
      reservesLeadingSpaceWhenUnselected: reservesLeadingSpaceWhenUnselected,
      isEnabled: isEnabled,
      separatorPolicy: separatorPolicy,
      isLastInSection: isLastInSection
    )
  }
}
