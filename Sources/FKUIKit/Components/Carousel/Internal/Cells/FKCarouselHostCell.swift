import UIKit

/// Collection cell that hosts a reusable page view from ``FKCarouselDataSource``.
final class FKCarouselHostCell: UICollectionViewCell {
  static let reuseIdentifier = "FKCarouselHostCell"

  private(set) var hostedView: UIView?
  private var hostConstraints: [NSLayoutConstraint] = []

  override func prepareForReuse() {
    super.prepareForReuse()
    detachHostedView()
  }

  func attach(_ view: UIView) {
    if hostedView === view {
      return
    }

    detachHostedView()
    hostedView = view
    view.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(view)
    hostConstraints = [
      view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      view.topAnchor.constraint(equalTo: contentView.topAnchor),
      view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ]
    NSLayoutConstraint.activate(hostConstraints)
  }

  private func detachHostedView() {
    NSLayoutConstraint.deactivate(hostConstraints)
    hostConstraints.removeAll()
    hostedView?.removeFromSuperview()
    hostedView = nil
  }
}
