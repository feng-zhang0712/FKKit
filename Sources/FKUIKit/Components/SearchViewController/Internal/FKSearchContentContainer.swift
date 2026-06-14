import UIKit

/// Swaps visibility between optional search-page and results child view controllers.
@MainActor
final class FKSearchContentContainer {
  enum VisibleSurface {
    case searchContent
    case results
    case none
  }

  private(set) var resultsViewController: UIViewController
  private(set) var searchContentViewController: UIViewController?
  private let containerView = UIView()
  private var embeddedChildren: [UIViewController] = []

  init(resultsViewController: UIViewController, searchContentViewController: UIViewController?) {
    self.resultsViewController = resultsViewController
    self.searchContentViewController = searchContentViewController
  }

  var container: UIView { containerView }

  func embed(in parent: UIViewController, below topAnchor: NSLayoutYAxisAnchor, in hostView: UIView) {
    containerView.translatesAutoresizingMaskIntoConstraints = false
    hostView.addSubview(containerView)
    NSLayoutConstraint.activate([
      containerView.topAnchor.constraint(equalTo: topAnchor),
      containerView.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
      containerView.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
      containerView.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
    ])

    embedChild(resultsViewController, in: parent)
    if let searchContentViewController {
      embedChild(searchContentViewController, in: parent)
    }
    setVisibleSurface(.results)
  }

  func replaceResultsViewController(_ viewController: UIViewController, in parent: UIViewController) {
    removeChild(resultsViewController)
    resultsViewController = viewController
    embedChild(viewController, in: parent)
    setVisibleSurface(.results)
  }

  func replaceSearchContentViewController(_ viewController: UIViewController?, in parent: UIViewController) {
    if let existing = searchContentViewController {
      removeChild(existing)
    }
    searchContentViewController = viewController
    if let viewController {
      embedChild(viewController, in: parent)
    }
  }

  func setVisibleSurface(_ surface: VisibleSurface) {
    searchContentViewController?.view.isHidden = surface != .searchContent
    resultsViewController.view.isHidden = surface != .results
    switch surface {
    case .searchContent:
      containerView.isHidden = searchContentViewController == nil
    case .results:
      containerView.isHidden = false
    case .none:
      containerView.isHidden = true
    }
  }

  private func embedChild(_ child: UIViewController, in parent: UIViewController) {
    parent.addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(child.view)
    NSLayoutConstraint.activate([
      child.view.topAnchor.constraint(equalTo: containerView.topAnchor),
      child.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      child.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      child.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])
    child.didMove(toParent: parent)
    embeddedChildren.append(child)
  }

  private func removeChild(_ child: UIViewController) {
    child.willMove(toParent: nil)
    child.view.removeFromSuperview()
    child.removeFromParent()
    embeddedChildren.removeAll { $0 === child }
  }
}
