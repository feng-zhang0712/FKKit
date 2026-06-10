import UIKit

enum FKCopyChipI18n {
  static func accessibilityLabel(summary: String) -> String {
    FKUIKitI18n.format("fkuikit.copy_chip.a11y.label", summary)
  }

  static var accessibilityHint: String {
    FKUIKitI18n.string("fkuikit.copy_chip.a11y.hint")
  }

  static var copiedAnnouncement: String {
    FKUIKitI18n.string("fkuikit.copy_chip.a11y.copied")
  }

  static var toastSuccess: String {
    FKUIKitI18n.string("fkuikit.copy_chip.toast.success")
  }
}
