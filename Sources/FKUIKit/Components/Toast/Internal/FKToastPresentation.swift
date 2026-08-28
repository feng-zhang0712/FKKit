import UIKit

/// Binds one in-flight request to its rendered view and layout state.
final class FKToastPresentation {
  var request: FKToastRequest
  let view: FKToastView
  let resolvedPosition: FKToastPosition
  let positionConstraint: NSLayoutConstraint
  weak var hostWindow: UIWindow?
  var hostTracker: FKToastHostTracker?

  init(
    request: FKToastRequest,
    view: FKToastView,
    resolvedPosition: FKToastPosition,
    positionConstraint: NSLayoutConstraint,
    hostWindow: UIWindow?,
    hostTracker: FKToastHostTracker? = nil
  ) {
    self.request = request
    self.view = view
    self.resolvedPosition = resolvedPosition
    self.positionConstraint = positionConstraint
    self.hostWindow = hostWindow
    self.hostTracker = hostTracker
  }
}
