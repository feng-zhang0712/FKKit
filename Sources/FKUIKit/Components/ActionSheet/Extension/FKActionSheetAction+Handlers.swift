import UIKit

public extension FKActionSheetAction {
  /// Invokes ``actionHandler`` when set.
  @MainActor
  func invokeHandlers() {
    actionHandler?(self)
  }
}

public extension FKActionSheetAction.Style {
  /// Maps `UIAlertAction.Style` to action sheet style.
  init(uiAlertActionStyle: UIAlertAction.Style) {
    switch uiAlertActionStyle {
    case .default:
      self = .default
    case .cancel:
      self = .cancel
    case .destructive:
      self = .destructive
    @unknown default:
      self = .default
    }
  }
}
