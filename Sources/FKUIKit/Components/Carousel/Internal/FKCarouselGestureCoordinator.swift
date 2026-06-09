import UIKit

/// Installs nested scroll and navigation pop gesture relationships.
@MainActor
final class FKCarouselGestureCoordinator {
  weak var carouselPanGesture: UIPanGestureRecognizer?
  weak var hostView: UIView?

  func refresh(
    policy: FKCarouselNestedScrollPolicy,
    requiresNavigationPopGestureToFail: Bool,
    in view: UIView,
    panGesture: UIPanGestureRecognizer
  ) {
    carouselPanGesture = panGesture
    hostView = view

    switch policy {
    case .standard:
      break

    case .failParentUntilCarouselAtEdge:
      installParentFailRelationships(for: view, panGesture: panGesture)

    case .simultaneous:
      installSimultaneousRelationships(panGesture: panGesture)
    }

    if requiresNavigationPopGestureToFail {
      installNavigationPopFailure(for: view, panGesture: panGesture)
    }
  }

  private func installParentFailRelationships(for view: UIView, panGesture: UIPanGestureRecognizer) {
    var ancestor = view.superview
    let hostScrollView = view.subviews.compactMap { $0 as? UIScrollView }.first
    while let current = ancestor {
      if let scrollView = current as? UIScrollView, scrollView !== hostScrollView {
        scrollView.panGestureRecognizer.require(toFail: panGesture)
      }
      ancestor = current.superview
    }
  }

  private func installSimultaneousRelationships(panGesture: UIPanGestureRecognizer) {
    panGesture.delegate = SimultaneousPanDelegate.shared
  }

  private func installNavigationPopFailure(for view: UIView, panGesture: UIPanGestureRecognizer) {
    guard
      let navigationController = view.fk_nearestNavigationController(),
      let popGesture = navigationController.interactivePopGestureRecognizer
    else { return }
    popGesture.require(toFail: panGesture)
  }
}

private final class SimultaneousPanDelegate: NSObject, UIGestureRecognizerDelegate {
  static let shared = SimultaneousPanDelegate()

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    true
  }
}

private extension UIView {
  func fk_nearestNavigationController() -> UINavigationController? {
    var responder: UIResponder? = self
    while let current = responder {
      if let viewController = current as? UIViewController {
        return viewController.navigationController
      }
      responder = current.next
    }
    return nil
  }
}
