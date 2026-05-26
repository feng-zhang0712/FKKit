import Foundation

/// Closure-based lifecycle callbacks for action sheet presentation.
public struct FKActionSheetLifecycleHooks {
  /// Called before the sheet animation starts.
  public var willPresent: (@MainActor () -> Void)?
  /// Called after the sheet animation finishes.
  public var didPresent: (@MainActor () -> Void)?
  /// Called before dismissal starts.
  public var willDismiss: (@MainActor (_ reason: FKActionSheetDismissReason) -> Void)?
  /// Called after dismissal finishes.
  public var didDismiss: (@MainActor (_ reason: FKActionSheetDismissReason) -> Void)?
  /// Called when the user selects an action row (excluding toggle changes).
  public var didSelect: (@MainActor (_ action: FKActionSheetAction) -> Void)?

  /// Creates an empty hook container.
  public init(
    willPresent: (@MainActor () -> Void)? = nil,
    didPresent: (@MainActor () -> Void)? = nil,
    willDismiss: (@MainActor (_ reason: FKActionSheetDismissReason) -> Void)? = nil,
    didDismiss: (@MainActor (_ reason: FKActionSheetDismissReason) -> Void)? = nil,
    didSelect: (@MainActor (_ action: FKActionSheetAction) -> Void)? = nil
  ) {
    self.willPresent = willPresent
    self.didPresent = didPresent
    self.willDismiss = willDismiss
    self.didDismiss = didDismiss
    self.didSelect = didSelect
  }
}
