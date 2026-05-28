import UIKit

/// Closure-based lifecycle handlers for teams that prefer lightweight integration.
///
/// Pair with ``FKSheetPresentationController/callbackDelivery`` to avoid duplicate delegate + handler delivery.
public struct FKSheetPresentationLifecycleHandlers {
  /// Called before the presentation animation starts.
  public var willPresent: (@MainActor () -> Void)?
  /// Called after the presentation animation finishes.
  public var didPresent: (@MainActor () -> Void)?
  /// Called before the dismissal animation starts.
  public var willDismiss: (@MainActor () -> Void)?
  /// Called after the dismissal animation finishes.
  public var didDismiss: (@MainActor () -> Void)?
  /// Called while interactive dismissal progresses.
  public var progress: (@MainActor (CGFloat) -> Void)?
  /// Called when the sheet’s selected detent changes.
  public var selectedDetentDidChange: (@MainActor (_ detent: FKSheetPresentationDetent, _ index: Int) -> Void)?

  /// Creates an empty callbacks container with optional closures.
  public init(
    willPresent: (@MainActor () -> Void)? = nil,
    didPresent: (@MainActor () -> Void)? = nil,
    willDismiss: (@MainActor () -> Void)? = nil,
    didDismiss: (@MainActor () -> Void)? = nil,
    progress: (@MainActor (CGFloat) -> Void)? = nil,
    selectedDetentDidChange: (@MainActor (_ detent: FKSheetPresentationDetent, _ index: Int) -> Void)? = nil
  ) {
    self.willPresent = willPresent
    self.didPresent = didPresent
    self.willDismiss = willDismiss
    self.didDismiss = didDismiss
    self.progress = progress
    self.selectedDetentDidChange = selectedDetentDidChange
  }
}
