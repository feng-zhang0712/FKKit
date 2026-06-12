import UIKit

/// Installs ``FKCellGroupedBackgroundView`` only when grouped chrome is required.
@MainActor
final class FKCellGroupedBackgroundHosting {
  private var background: FKCellGroupedBackgroundView?
  private var constraints: [NSLayoutConstraint] = []

  /// Applies grouped background configuration, attaching to `parent` only when non-nil.
  func apply(_ configuration: FKCellGroupConfiguration?, in parent: UIView) {
    if let configuration {
      ensureInstalled(in: parent)
      background?.apply(configuration)
    } else {
      detach()
    }
  }

  /// Removes any installed grouped background from the hierarchy.
  func detach() {
    background?.removeFromSuperview()
    background = nil
    NSLayoutConstraint.deactivate(constraints)
    constraints = []
  }

  private func ensureInstalled(in parent: UIView) {
    guard background == nil else { return }
    let view = FKCellGroupedBackgroundView()
    view.translatesAutoresizingMaskIntoConstraints = false
    parent.insertSubview(view, at: 0)
    constraints = [
      view.topAnchor.constraint(equalTo: parent.topAnchor),
      view.leadingAnchor.constraint(equalTo: parent.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: parent.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: parent.bottomAnchor),
    ]
    NSLayoutConstraint.activate(constraints)
    background = view
  }
}
