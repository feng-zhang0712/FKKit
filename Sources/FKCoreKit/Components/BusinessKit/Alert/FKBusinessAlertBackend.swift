import Foundation
import UIKit

/// Selects how BusinessKit presents modal alerts (version prompts, ``FKBusinessAlertManaging``).
public enum FKBusinessAlertBackend: Sendable, Equatable {
  /// Presents ``UIAlertController`` (default, no FKUIKit dependency).
  case systemAlert

  /// Delegates to an injected ``FKBusinessAlertPresenting`` implementation (for example FKAlert in the app target).
  case fkAlert
}

/// Host-provided alert presenter used when ``FKBusinessAlertBackend/fkAlert`` is selected.
///
/// Implement in the app layer and bind to ``FKAlertPresenter`` without adding an FKUIKit dependency to FKCoreKit.
public protocol FKBusinessAlertPresenting: AnyObject {
  /// Presents an alert once for a given identifier.
  @MainActor
  func presentOnce(
    id: String,
    title: String?,
    message: String?,
    actions: [FKAlertAction],
    from presenter: UIViewController?
  )
}
