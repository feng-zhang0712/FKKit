import UIKit

/// Optional delegate callbacks for action sheet lifecycle and row selection.
@MainActor
public protocol FKActionSheetDelegate: AnyObject {
  /// Called before the presentation animation starts.
  func actionSheetWillPresent(_ actionSheet: FKActionSheet)
  /// Called after the presentation animation finishes.
  func actionSheetDidPresent(_ actionSheet: FKActionSheet)
  /// Called before dismissal starts.
  func actionSheetWillDismiss(_ actionSheet: FKActionSheet, reason: FKActionSheetDismissReason)
  /// Called after dismissal finishes.
  func actionSheetDidDismiss(_ actionSheet: FKActionSheet, reason: FKActionSheetDismissReason)
  /// Called when the user selects an action row.
  func actionSheet(_ actionSheet: FKActionSheet, didSelect action: FKActionSheetAction)
}

public extension FKActionSheetDelegate {
  func actionSheetWillPresent(_ actionSheet: FKActionSheet) {}
  func actionSheetDidPresent(_ actionSheet: FKActionSheet) {}
  func actionSheetWillDismiss(_ actionSheet: FKActionSheet, reason: FKActionSheetDismissReason) {}
  func actionSheetDidDismiss(_ actionSheet: FKActionSheet, reason: FKActionSheetDismissReason) {}
  func actionSheet(_ actionSheet: FKActionSheet, didSelect action: FKActionSheetAction) {}
}
