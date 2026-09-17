import ObjectiveC.runtime
import UIKit

public extension UIScrollView {
  /// Sticky / affix engine associated with this scroll view.
  ///
  /// Lazily created on first access and retained for the lifetime of the scroll view unless cleared.
  var fk_stickyEngine: FKStickyEngine {
    if let existing = objc_getAssociatedObject(self, &FKStickyAssociationKeys.engine) as? FKStickyEngine {
      if existing.scrollView !== self {
        existing.scrollView = self
      }
      return existing
    }
    let engine = FKStickyEngine()
    engine.scrollView = self
    objc_setAssociatedObject(
      self,
      &FKStickyAssociationKeys.engine,
      engine,
      .OBJC_ASSOCIATION_RETAIN_NONATOMIC
    )
    return engine
  }

  /// Adds a sticky target to ``fk_stickyEngine``.
  @discardableResult
  func fk_addStickyTarget(
    id: String,
    view: UIView,
    isEnabled: Bool = true,
    priority: Int = 0,
    stickyInsetOverride: CGFloat? = nil,
    onProgressChange: ((FKStickyProgress) -> Void)? = nil
  ) -> FKStickyTarget {
    fk_stickyEngine.addTarget(
      id: id,
      view: view,
      isEnabled: isEnabled,
      priority: priority,
      stickyInsetOverride: stickyInsetOverride,
      onProgressChange: onProgressChange
    )
  }

  /// Recomputes natural origins and runs a sticky layout pass.
  func fk_reloadStickyLayout() {
    fk_stickyEngine.reloadLayout()
  }

  /// Unsticks all targets and optionally stops observation.
  func fk_resetSticky(stopObserving: Bool = false) {
    fk_stickyEngine.reset(stopObserving: stopObserving)
  }

  /// Forwards a scroll tick when automatic observation is disabled.
  func fk_handleStickyScroll() {
    fk_stickyEngine.handleScroll()
  }
}
