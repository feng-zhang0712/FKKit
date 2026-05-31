import Foundation
import UIKit

/// Observes page lifecycle and interactive transition progress for ``FKPagingController``.
@MainActor
public protocol FKPagingControllerDelegate: AnyObject {
  /// Called whenever ``FKPagingController/stateSnapshot``’s phase changes.
  func pagingController(_ controller: FKPagingController, didChangePhase phase: FKPagingPhase)
  /// Called after the container settles on a page (interactive or programmatic).
  func pagingController(_ controller: FKPagingController, didSettleAt index: Int)
  /// Called when tab and paging phases or progress change together during a transition.
  ///
  /// Prefer this over inferring progress from phase alone — it carries tab indicator phase, paging phase, and normalized drag progress.
  func pagingController(
    _ controller: FKPagingController,
    didUpdateCombinedTransition tabPhase: FKTabBarSwitchPhase,
    pagingPhase: FKPagingPhase,
    progress: CGFloat
  )
  /// Called before a page view controller becomes the settled visible page at `index`.
  func pagingController(_ controller: FKPagingController, willDisplayPage viewController: UIViewController, at index: Int)
  /// Called after a page finishes settling as the visible page at `index`.
  func pagingController(_ controller: FKPagingController, didDisplayPage viewController: UIViewController, at index: Int)
  /// Called when a page leaves the pager host (lazy cache eviction, invalidation, or content reset).
  func pagingController(_ controller: FKPagingController, didEndDisplayingPage viewController: UIViewController, at index: Int)
  /// Called before committing a switch to `index`. Return `false` to cancel the switch.
  func pagingController(
    _ controller: FKPagingController,
    shouldSwitchTo index: Int,
    reason: FKPagingSwitchReason
  ) -> Bool
  /// Called when a controlled gate or veto path records a deferred target index.
  func pagingController(
    _ controller: FKPagingController,
    didRequestPageSwitchTo index: Int,
    reason: FKPagingSwitchReason
  )
  /// Called when ``FKPagingController/pendingPageIndex`` is cleared without settling on the deferred page.
  func pagingControllerDidCancelPendingPageSwitch(_ controller: FKPagingController)
}

@MainActor
public extension FKPagingControllerDelegate {
  func pagingController(_ controller: FKPagingController, didChangePhase phase: FKPagingPhase) {}
  func pagingController(_ controller: FKPagingController, didSettleAt index: Int) {}
  func pagingController(
    _ controller: FKPagingController,
    didUpdateCombinedTransition tabPhase: FKTabBarSwitchPhase,
    pagingPhase: FKPagingPhase,
    progress: CGFloat
  ) {}
  func pagingController(_ controller: FKPagingController, willDisplayPage viewController: UIViewController, at index: Int) {}
  func pagingController(_ controller: FKPagingController, didDisplayPage viewController: UIViewController, at index: Int) {}
  func pagingController(_ controller: FKPagingController, didEndDisplayingPage viewController: UIViewController, at index: Int) {}
  func pagingController(
    _ controller: FKPagingController,
    shouldSwitchTo index: Int,
    reason: FKPagingSwitchReason
  ) -> Bool { true }
  func pagingController(
    _ controller: FKPagingController,
    didRequestPageSwitchTo index: Int,
    reason: FKPagingSwitchReason
  ) {}
  func pagingControllerDidCancelPendingPageSwitch(_ controller: FKPagingController) {}
}

#if canImport(SwiftUI)
import SwiftUI

/// Optional SwiftUI callbacks mirrored from ``FKPagingControllerDelegate`` beyond index binding.
@MainActor
public struct FKPagingControllerRepresentableCallbacks {
  public var onPendingPageIndexChanged: ((Int?) -> Void)?
  public var onProgressUpdate: ((CGFloat, Int, Int) -> Void)?
  public var onPhaseChanged: ((FKPagingPhase) -> Void)?
  public var onWillDisplayPage: ((Int) -> Void)?
  public var onDidDisplayPage: ((Int) -> Void)?
  public var onDidEndDisplayingPage: ((Int) -> Void)?

  public init(
    onPendingPageIndexChanged: ((Int?) -> Void)? = nil,
    onProgressUpdate: ((CGFloat, Int, Int) -> Void)? = nil,
    onPhaseChanged: ((FKPagingPhase) -> Void)? = nil,
    onWillDisplayPage: ((Int) -> Void)? = nil,
    onDidDisplayPage: ((Int) -> Void)? = nil,
    onDidEndDisplayingPage: ((Int) -> Void)? = nil
  ) {
    self.onPendingPageIndexChanged = onPendingPageIndexChanged
    self.onProgressUpdate = onProgressUpdate
    self.onPhaseChanged = onPhaseChanged
    self.onWillDisplayPage = onWillDisplayPage
    self.onDidDisplayPage = onDidDisplayPage
    self.onDidEndDisplayingPage = onDidEndDisplayingPage
  }
}
#endif
