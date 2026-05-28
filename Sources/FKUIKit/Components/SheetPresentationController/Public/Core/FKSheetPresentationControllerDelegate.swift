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
