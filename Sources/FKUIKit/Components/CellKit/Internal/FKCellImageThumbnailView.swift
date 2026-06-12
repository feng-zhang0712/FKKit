import UIKit

/// Fixed-size ``FKImageView`` thumbnail with reuse-safe cancellation.
@MainActor
final class FKCellImageThumbnailView: UIView {
  private let imageView = FKImageView(profile: .listCell)

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(content: FKCellImageContent) {
    if let url = content.url {
      imageView.load(url: url)
    } else if let image = content.image {
      imageView.setImage(image, animated: false)
    } else {
      imageView.resetForReuse()
    }
  }

  func resetForReuse() {
    imageView.resetForReuse()
  }

  private func commonInit() {
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 8
    imageView.layer.cornerCurve = .continuous
    addSubview(imageView)
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: topAnchor),
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}
