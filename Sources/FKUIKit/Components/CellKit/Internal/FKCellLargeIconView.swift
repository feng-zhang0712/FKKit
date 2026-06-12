import UIKit

/// Large app-icon style leading image for info rows (D-05).
@MainActor
final class FKCellLargeIconView: UIView {
  private let imageView = UIImageView()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  override var intrinsicContentSize: CGSize {
    CGSize(width: FKCellLayoutMetrics.infoIconSide, height: FKCellLayoutMetrics.infoIconSide)
  }

  func apply(_ content: FKCellIconContent) {
    if let image = content.image {
      imageView.image = image
      imageView.tintColor = nil
    } else if let symbolName = content.symbolName {
      let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
      imageView.image = UIImage(systemName: symbolName, withConfiguration: config)
      imageView.tintColor = content.configuration.appearance.defaultTintColor
    } else {
      imageView.image = nil
    }
    isHidden = imageView.image == nil
  }

  func reset() {
    imageView.image = nil
    isHidden = true
  }

  private func commonInit() {
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.layer.cornerRadius = 12
    imageView.layer.cornerCurve = .continuous
    addSubview(imageView)
    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: topAnchor),
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
      widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.infoIconSide),
      heightAnchor.constraint(equalToConstant: FKCellLayoutMetrics.infoIconSide),
    ])
  }
}
