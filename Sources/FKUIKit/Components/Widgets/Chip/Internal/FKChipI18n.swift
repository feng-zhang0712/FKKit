import UIKit

enum FKChipI18n {
  static func removeLabel(title: String) -> String {
    FKUIKitI18n.format("fkuikit.chip.remove", title)
  }

  static func filterLabel(title: String, selected: Bool, roleDescription: String? = nil) -> String {
    if let roleDescription {
      return FKUIKitI18n.format(
        selected ? "fkuikit.chip.filter.role.selected" : "fkuikit.chip.filter.role.unselected",
        title,
        roleDescription
      )
    }
    return FKUIKitI18n.format(
      selected ? "fkuikit.chip.filter.selected" : "fkuikit.chip.filter.unselected",
      title
    )
  }

  static func groupSelectionCount(_ count: Int) -> String {
    FKUIKitI18n.format("fkuikit.chipgroup.selection_count", count)
  }
}
