import UIKit

struct FKCalloutRequest {
  let id: UUID
  var content: FKCalloutContent
  var configuration: FKCalloutConfiguration
  var hooks: FKCalloutLifecycleHooks
  weak var anchorView: UIView?
  var sourceRect: CGRect?
  var actionHandlers: [String: @MainActor () -> Void]
  var menuSelectionHandler: (@MainActor (FKCalloutMenuItem) -> Void)?
  var closeHandler: (@MainActor () -> Void)?
  var customBeakViewProvider: (@MainActor @Sendable () -> UIView)?
}

@MainActor
final class FKCalloutPresentation {
  let id: UUID
  var request: FKCalloutRequest
  let overlayView: FKCalloutOverlayView
  weak var hostWindow: UIWindow?
  var anchorObserver: FKCalloutAnchorObserver?

  init(id: UUID, request: FKCalloutRequest, overlayView: FKCalloutOverlayView, hostWindow: UIWindow?) {
    self.id = id
    self.request = request
    self.overlayView = overlayView
    self.hostWindow = hostWindow
  }
}
