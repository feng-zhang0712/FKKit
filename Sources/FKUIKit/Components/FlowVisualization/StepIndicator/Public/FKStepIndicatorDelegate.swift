import UIKit

/// Optional delegate callbacks for ``FKStepIndicator`` selection.
@MainActor
public protocol FKStepIndicatorDelegate: AnyObject {
  /// Return `false` to prevent selection at `index`.
  func stepIndicator(_ indicator: FKStepIndicator, shouldSelectStepAt index: Int) -> Bool
  /// Called after a step is selected.
  func stepIndicator(_ indicator: FKStepIndicator, didSelectStepAt index: Int)
}

extension FKStepIndicatorDelegate {
  public func stepIndicator(_ indicator: FKStepIndicator, shouldSelectStepAt index: Int) -> Bool {
    true
  }

  public func stepIndicator(_ indicator: FKStepIndicator, didSelectStepAt index: Int) {}
}
