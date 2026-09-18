import ObjectiveC.runtime
import UIKit

public extension UIScrollView {
  /// Navigation-bar scroll-transition engine associated with this scroll view.
  ///
  /// Lazily created on first access and retained for the lifetime of the scroll view unless cleared.
  var fk_navigationBarScrollEngine: FKNavigationBarScrollEngine {
    if let existing = objc_getAssociatedObject(
      self,
      &FKNavigationBarScrollAssociationKeys.engine
    ) as? FKNavigationBarScrollEngine {
      if existing.scrollView !== self {
        existing.scrollView = self
      }
      return existing
    }
    let engine = FKNavigationBarScrollEngine()
    engine.scrollView = self
    objc_setAssociatedObject(
      self,
      &FKNavigationBarScrollAssociationKeys.engine,
      engine,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
    return engine
  }

  /// Forwards a scroll tick when automatic observation is disabled.
  func fk_handleNavigationBarScroll() {
    fk_navigationBarScrollEngine.handleScroll()
  }

  /// Recomputes progress from the current offset and reapplies chrome when configured.
  func fk_reloadNavigationBarScroll() {
    fk_navigationBarScrollEngine.reload()
  }

  /// Clears forced progress and optionally stops observation.
  func fk_resetNavigationBarScroll(stopObserving: Bool = false) {
    fk_navigationBarScrollEngine.reset(stopObserving: stopObserving)
  }
}
