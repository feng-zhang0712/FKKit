import UIKit

/// Receives alert lifecycle callbacks from ``FKAlertPresenter``.
@MainActor
public protocol FKAlertDelegate: AnyObject {
  /// Called immediately before the alert presentation animation starts.
  func alertWillPresent(_ alert: FKAlertViewController)
  /// Called after the alert finishes dismissing.
  func alertDidDismiss(_ alert: FKAlertViewController, result: FKAlertResult)
}

public extension FKAlertDelegate {
  /// Default empty implementation.
  func alertWillPresent(_ alert: FKAlertViewController) {}
  /// Default empty implementation.
  func alertDidDismiss(_ alert: FKAlertViewController, result: FKAlertResult) {}
}
