import Foundation

/// Sendable chip payload for ``FKChipGroup``.
public struct FKChipItem: Sendable, Equatable, Identifiable {
  public var id: String
  public var title: String
  public var leadingIcon: FKChipIcon?
  public var isSelected: Bool
  public var isEnabled: Bool
  public var showsRemoveButton: Bool

  public init(
    id: String,
    title: String,
    leadingIcon: FKChipIcon? = nil,
    isSelected: Bool = false,
    isEnabled: Bool = true,
    showsRemoveButton: Bool = false
  ) {
    self.id = id
    self.title = title
    self.leadingIcon = leadingIcon
    self.isSelected = isSelected
    self.isEnabled = isEnabled
    self.showsRemoveButton = showsRemoveButton
  }
}

extension FKChipItem {
  public static func == (lhs: FKChipItem, rhs: FKChipItem) -> Bool {
    lhs.id == rhs.id
      && lhs.title == rhs.title
      && lhs.leadingIcon == rhs.leadingIcon
      && lhs.isSelected == rhs.isSelected
      && lhs.isEnabled == rhs.isEnabled
      && lhs.showsRemoveButton == rhs.showsRemoveButton
  }
}
