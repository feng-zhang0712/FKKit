import UIKit

/// Collection cell that hosts a reusable page view from ``FKCarouselDataSource``.
final class FKCarouselHostCell: UICollectionViewCell {
  static let reuseIdentifier = "FKCarouselHostCell"

  private(set) var hostedView: UIView?

  override func prepareForReuse() {
    super.prepareForReuse()
    hostedView?.removeFromSuperview()
    hostedView = nil
  }

  func attach(_ view: UIView) {
    if hostedView !== view {
      hostedView?.removeFromSuperview()
      hostedView = view
      contentView.addSubview(view)
      view.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        view.topAnchor.constraint(equalTo: contentView.topAnchor),
        view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      ])
    }
  }
}
