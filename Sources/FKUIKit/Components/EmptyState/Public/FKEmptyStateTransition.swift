import Foundation

/// Content update animation used by ``FKEmptyStateView/apply(_:animated:)`` and in-place overlay updates.
///
/// Show/hide fade timing still uses ``FKEmptyStatePresentationConfiguration/fadeDuration`` on host extensions.
/// Respects Reduce Motion (updates apply without animation).
public enum FKEmptyStateTransition: Equatable, Sendable {
  /// Applies content updates instantly (default).
  case none
  /// Cross-fades from the previous content snapshot to the updated layout.
  case crossDissolve
  /// Opacity fade on the content container.
  case fade
  /// Subtle scale-up from 92% with ease-out.
  case scale
  /// Slide up from below with fade-in.
  case slideUp
}
