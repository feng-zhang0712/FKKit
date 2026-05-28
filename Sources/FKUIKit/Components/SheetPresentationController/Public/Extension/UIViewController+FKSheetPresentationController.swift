import UIKit

public extension UIViewController {
  /// Presents content with ``FKSheetPresentationController`` and returns the active controller instance.
  ///
  /// Retain the returned controller when you need programmatic ``FKSheetPresentationController/dismiss(animated:completion:)``,
  /// ``FKSheetPresentationController/selectDetent(_:animated:)``, or ``FKSheetPresentationController/updateLayout(animated:duration:options:)``.
  @discardableResult
  @MainActor
  func fk_presentSheet(
    contentController: UIViewController,
    configuration: FKSheetPresentationConfiguration = .default,
    delegate: FKSheetPresentationControllerDelegate? = nil,
    handlers: FKSheetPresentationLifecycleHandlers = .init(),
    callbackDelivery: FKSheetPresentationCallbackDelivery = .handlersOnly,
    animated: Bool = true,
    completion: (@MainActor () -> Void)? = nil
  ) -> FKSheetPresentationController {
    FKSheetPresentationController.present(
      contentController: contentController,
      from: self,
      configuration: configuration,
      delegate: delegate,
      handlers: handlers,
      callbackDelivery: callbackDelivery,
      animated: animated,
      completion: completion
    )
  }
}
