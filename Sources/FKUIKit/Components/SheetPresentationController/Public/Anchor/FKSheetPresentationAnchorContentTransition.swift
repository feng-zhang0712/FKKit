import Foundation

/// Content transition used when replacing anchor-hosted children in place.
public enum FKSheetPresentationAnchorContentTransition: Sendable, Equatable {
  /// Swaps content without a content-level animation (layout may still animate).
  case none
  /// Crossfades between outgoing and incoming content.
  case crossfade(duration: TimeInterval)
  /// Slides incoming content vertically while fading the outgoing content.
  case slideVertical(direction: SlideDirection, duration: TimeInterval)

  /// Vertical slide direction for ``slideVertical(direction:duration:)``.
  public enum SlideDirection: Sendable, Equatable {
    case up
    case down
  }
}
