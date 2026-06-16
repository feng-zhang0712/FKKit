#if canImport(UIKit)
import UIKit

public extension UIViewController {
  /// Resolves the top-most view controller in the foreground-active window scene.
  ///
  /// Walks `UINavigationController`, `UITabBarController`, and the presented-view-controller chain.
  /// Returns `nil` when no key window or root controller is available.
  @MainActor
  static func fk_topMostViewController(in application: UIApplication = .shared) -> UIViewController? {
    let windowScene = application.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    let window = windowScene?.windows.first { $0.isKeyWindow } ?? windowScene?.windows.first
    return window?.fk_topViewController
  }

  /// Recursively returns the top-most presented view controller from `self`.
  var fk_topMostPresented: UIViewController {
    var top: UIViewController = self
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }

  /// Ends editing on the controller's view, dismissing the keyboard when active.
  func fk_endEditing() {
    view.endEditing(true)
  }

  /// Adds a child controller and pins its view to the receiver's view with Auto Layout.
  func fk_addFullScreenChild(_ child: UIViewController) {
    addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(child.view)
    NSLayoutConstraint.activate([
      child.view.topAnchor.constraint(equalTo: view.topAnchor),
      child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
    ])
    child.didMove(toParent: self)
  }

  /// Removes `self` from its parent safely when embedded as a child.
  func fk_removeFromParentSafely() {
    guard parent != nil else { return }
    willMove(toParent: nil)
    view.removeFromSuperview()
    removeFromParent()
  }
}

#endif
