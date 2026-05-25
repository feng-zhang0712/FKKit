import UIKit

public extension FKActionSheetAction {
  /// Invokes ``actionHandler`` when set; otherwise invokes ``handler``.
  ///
  /// - Important: When both closures are set, only ``actionHandler`` is called.
  @MainActor
  func invokeHandlers() {
    if let actionHandler {
      actionHandler(self)
    } else {
      handler?()
    }
  }
}

public extension FKActionSheetAction.Style {
  /// Maps `UIAlertAction.Style` to action sheet style.
  public init(uiAlertActionStyle: UIAlertAction.Style) {
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
