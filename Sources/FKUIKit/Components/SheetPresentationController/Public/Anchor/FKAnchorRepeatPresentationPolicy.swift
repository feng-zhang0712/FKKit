import Foundation

/// Controls what happens when ``FKSheetPresentationController/present(from:animated:completion:)`` is called
/// while another anchor popup is already visible for the same anchor scope.
///
/// Anchor scope is defined by the resolved host view plus the anchor's view-based source (when applicable).
/// Rect-only anchors are scoped by host view only.
///
/// - Note: Re-tapping with the **same** ``FKSheetPresentationController`` instance is still a no-op while presented.
///   Use ``FKSheetPresentationController/presentOrReplaceAnchorContent(from:contentController:replacement:presentAnimated:completion:)``
///   to swap content on an existing instance.
public enum FKAnchorRepeatPresentationPolicy: Sendable, Equatable {
  /// Dismisses the popup already shown for this anchor scope, then presents the new request.
  ///
  /// Recommended default when each tap creates a new ``FKSheetPresentationController`` (prevents stacked masks).
  case replaceExisting(dismissAnimated: Bool = true)

  /// Keeps the existing popup and completes without presenting again.
  case ignoreIfAlreadyPresented

  /// Dismisses the existing popup without presenting (tap-again-to-close for the same anchor scope).
  case toggle(dismissAnimated: Bool = true)
}
