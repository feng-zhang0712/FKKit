import UIKit

/// Optional callbacks for value changes on ``FKRatingControl``.
@MainActor
public protocol FKRatingControlDelegate: AnyObject {
  /// Called before the control updates its value (user or programmatic when `sendsControlEvents` is `true`).
  func ratingControl(_ control: FKRatingControl, willChangeValue to: Double)

  /// Called after the value, layout, and accessibility state have been updated.
  func ratingControl(_ control: FKRatingControl, didChangeValue to: Double)
}

public extension FKRatingControlDelegate {
  func ratingControl(_ control: FKRatingControl, willChangeValue to: Double) {}
}
