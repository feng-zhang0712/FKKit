import UIKit

/// Mounts one visible child view controller at a time for search content vs results.
@MainActor
final class FKSearchContentContainer {
  enum VisibleSurface: Equatable {
    case searchContent
    case results
    case none
  }

  private(set) var resultsViewController: UIViewController
  private(set) var searchContentViewController: UIViewController?

  private let contentLayoutGuide = UILayoutGuide()
  private weak var parent: UIViewController?
  private weak var hostView: UIView?
  private var mountedSurface: VisibleSurface?
  private var mountedViewController: UIViewController?

  init(resultsViewController: UIViewController, searchContentViewController: UIViewController?) {
    self.resultsViewController = resultsViewController
    self.searchContentViewController = searchContentViewController
  }

  func embed(in parent: UIViewController, below topAnchor: NSLayoutYAxisAnchor, in hostView: UIView) {
    embed(
      in: parent,
      topAnchor: topAnchor,
      bottomAnchor: hostView.bottomAnchor,
      in: hostView
    )
  }

  func embed(
    in parent: UIViewController,
    topAnchor: NSLayoutYAxisAnchor,
    bottomAnchor: NSLayoutYAxisAnchor,
    in hostView: UIView
  ) {
    self.parent = parent
    self.hostView = hostView

    hostView.addLayoutGuide(contentLayoutGuide)
    NSLayoutConstraint.activate([
      contentLayoutGuide.topAnchor.constraint(equalTo: topAnchor),
      contentLayoutGuide.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
      contentLayoutGuide.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
      contentLayoutGuide.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    setVisibleSurface(.results)
  }

  func setVisibleSurface(_ surface: VisibleSurface) {
    guard mountedSurface != surface else { return }

    switch surface {
    case .none:
      unmountCurrentChild()
    case .results:
      mountChild(resultsViewController)
    case .searchContent:
      guard let searchContentViewController else {
        unmountCurrentChild()
        mountedSurface = VisibleSurface.none
        return
      }
      mountChild(searchContentViewController)
    }

    mountedSurface = surface
  }

  private func mountChild(_ child: UIViewController) {
    guard mountedViewController !== child else { return }
    unmountCurrentChild()

    guard let parent, let hostView else { return }

    parent.addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    hostView.addSubview(child.view)
    NSLayoutConstraint.activate([
      child.view.topAnchor.constraint(equalTo: contentLayoutGuide.topAnchor),
      child.view.leadingAnchor.constraint(equalTo: contentLayoutGuide.leadingAnchor),
      child.view.trailingAnchor.constraint(equalTo: contentLayoutGuide.trailingAnchor),
      child.view.bottomAnchor.constraint(equalTo: contentLayoutGuide.bottomAnchor),
    ])
    child.didMove(toParent: parent)
    mountedViewController = child
  }

  private func unmountCurrentChild() {
    guard let child = mountedViewController else { return }
    child.willMove(toParent: nil)
    child.view.removeFromSuperview()
    child.removeFromParent()
    mountedViewController = nil
  }
}
