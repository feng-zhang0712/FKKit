import UIKit

/// Delegate hooks for FKSheetPresentationController lifecycle and interactive progress.
@MainActor
public protocol FKSheetPresentationControllerDelegate: AnyObject {
  /// Called before the presentation animation starts.
  func presentationControllerWillPresent(_ controller: FKSheetPresentationController)
  /// Called after the presentation animation finishes.
  func presentationControllerDidPresent(_ controller: FKSheetPresentationController)
  /// Called before the dismissal animation starts.
  func presentationControllerWillDismiss(_ controller: FKSheetPresentationController)
  /// Called after the dismissal animation finishes.
  func presentationControllerDidDismiss(_ controller: FKSheetPresentationController)
  /// Called while interactive dismissal progresses.
  func presentationController(_ controller: FKSheetPresentationController, didUpdateProgress progress: CGFloat)
  /// Called when the sheet’s selected detent changes (analogous to `UISheetPresentationControllerDelegate.sheetPresentationControllerDidChangeSelectedDetentIdentifier`).
  func presentationController(_ controller: FKSheetPresentationController, didChangeSelectedDetent detent: FKSheetPresentationDetent, at index: Int)
}

public extension FKSheetPresentationControllerDelegate {
  func presentationControllerWillPresent(_ controller: FKSheetPresentationController) {}
  func presentationControllerDidPresent(_ controller: FKSheetPresentationController) {}
  func presentationControllerWillDismiss(_ controller: FKSheetPresentationController) {}
  func presentationControllerDidDismiss(_ controller: FKSheetPresentationController) {}
  func presentationController(_ controller: FKSheetPresentationController, didUpdateProgress progress: CGFloat) {}
  func presentationController(_ controller: FKSheetPresentationController, didChangeSelectedDetent detent: FKSheetPresentationDetent, at index: Int) {}
}

/// Closure-based lifecycle handlers for teams that prefer lightweight integration.
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
