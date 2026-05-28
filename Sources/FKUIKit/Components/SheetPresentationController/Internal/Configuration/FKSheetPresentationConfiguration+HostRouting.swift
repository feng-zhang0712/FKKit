import UIKit

extension FKSheetPresentationConfiguration {
  /// Whether presentation must use the in-hierarchy overlay host for touch passthrough outside the popup.
  var requiresPassthroughOverlayHost: Bool {
    if backgroundInteraction.isEnabled { return true }
    if case let .dim(_, alpha) = backdropStyle, alpha <= 0 {
      return zeroDimBackdropBehavior == .passthrough
    }
    return false
  }
}
