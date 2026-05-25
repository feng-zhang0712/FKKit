import UIKit

/// Optional delegate callbacks for action sheet lifecycle and row selection.
@MainActor
public protocol FKActionSheetDelegate: AnyObject {
  /// Called before the presentation animation starts.
  func actionSheetWillPresent(_ handle: FKActionSheetHandle)
  /// Called after the presentation animation finishes.
  func actionSheetDidPresent(_ handle: FKActionSheetHandle)
  /// Called before dismissal starts.
  func actionSheetWillDismiss(_ handle: FKActionSheetHandle, reason: FKActionSheetDismissReason)
  /// Called after dismissal finishes.
  func actionSheetDidDismiss(_ handle: FKActionSheetHandle, reason: FKActionSheetDismissReason)
  /// Called when the user selects an action row.
  func actionSheet(_ handle: FKActionSheetHandle, didSelect action: FKActionSheetAction)
}

public extension FKActionSheetDelegate {
  func actionSheetWillPresent(_ handle: FKActionSheetHandle) {}
  func actionSheetDidPresent(_ handle: FKActionSheetHandle) {}
  func actionSheetWillDismiss(_ handle: FKActionSheetHandle, reason: FKActionSheetDismissReason) {}
  func actionSheetDidDismiss(_ handle: FKActionSheetHandle, reason: FKActionSheetDismissReason) {}
  func actionSheet(_ handle: FKActionSheetHandle, didSelect action: FKActionSheetAction) {}
}
