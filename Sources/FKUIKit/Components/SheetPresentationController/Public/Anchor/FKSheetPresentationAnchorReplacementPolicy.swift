import Foundation

/// Controls how anchor-hosted content is replaced while a popup is already visible.
public enum FKSheetPresentationAnchorReplacementPolicy: Sendable, Equatable {
  /// Dismisses the current popup, then presents the new content (each phase can animate independently).
  case dismissThenPresent(dismissAnimated: Bool, presentAnimated: Bool)
  /// Keeps the popup presented and swaps content in place, then relayouts to the new height.
  case replaceInPlace(
    contentTransition: FKSheetPresentationAnchorContentTransition = .crossfade(duration: 0.18),
    animateLayout: Bool = true,
    layoutAnimationDuration: TimeInterval = 0.24
  )
}
