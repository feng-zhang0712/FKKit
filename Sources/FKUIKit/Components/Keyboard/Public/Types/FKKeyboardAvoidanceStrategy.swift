import Foundation

/// Strategy used to avoid keyboard occlusion for sheets, forms, and custom hosts.
///
/// Owned by ``FKKeyboard`` / ``FKKeyboardAvoidanceController``. Also used by
/// `FKSheetPresentationConfiguration` keyboard avoidance.
///
/// ``FKKeyboardAvoidanceController`` never applies a transform to a ``UIScrollView``.
/// If ``adjustContainer`` / ``interactive`` would target a scroll view, it falls back to
/// ``adjustContentInsets`` automatically.
public enum FKKeyboardAvoidanceStrategy: Equatable, Sendable {
  /// Disables keyboard avoidance.
  case disabled
  /// Translates a **non-scrolling** container just enough for the focused field (or container bottom)
  /// to clear the keyboard.
  ///
  /// Best for fixed bottom cards / compact forms. Not for full-screen scroll views.
  case adjustContainer
  /// Adds keyboard overlap to scroll-view content and indicator insets, then scrolls the focused
  /// field into the inset-adjusted visible area.
  ///
  /// Recommended for scrollable forms and lists.
  case adjustContentInsets
  /// Best-effort interactive tracking (v1 uses the same translation rules as ``adjustContainer``,
  /// with the same scroll-view → insets fallback).
  case interactive
}
