import UIKit

@MainActor
final class FKPagingGestureCoordinator: NSObject, UIGestureRecognizerDelegate {
  var policy: FKPagingGesturePolicy = .preferNavigationBackGesture(edgeWidth: 24)

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    switch policy {
    case .exclusive:
      return false
    case .allowSimultaneous:
      return true
    case .preferNavigationBackGesture:
      return otherGestureRecognizer == gestureRecognizer.view?.window?.rootViewController?.navigationController?.interactivePopGestureRecognizer
    }
  }

  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    guard case .preferNavigationBackGesture(let edgeWidth) = policy else { return true }
    guard let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else { return true }
    let location = pan.location(in: view)
    let velocity = pan.velocity(in: view)
    if location.x <= edgeWidth && velocity.x > abs(velocity.y) {
      return false
    }
    return true
  }
}
