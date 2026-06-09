import FKCoreKit
import UIKit

/// Image banner collection cell backed by ``FKImageView`` and ``FKImageBannerOverlayView``.
@MainActor
final class FKImageBannerPageCell: UICollectionViewCell {
  static let reuseIdentifier = "FKImageBannerPageCell"

  let imageView = FKImageView(profile: .minimal)
  private let overlayView = FKImageBannerOverlayView()

  var configuration: FKImageBannerConfiguration = .init() {
    didSet {
      overlayView.configuration = configuration
      applyImageContentMode()
      applyCardStyleIfNeeded()
    }
  }

  var onCTATap: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    imageView.resetForReuse()
    overlayView.resetForReuse()
    onCTATap = nil
    contentView.fk_hideSkeleton(animated: false)
    contentView.fk_resetCornerShadow()
    contentView.layer.cornerRadius = 0
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    applyCardStyleIfNeeded()
  }

  private func commonInit() {
    contentView.clipsToBounds = true

    imageView.translatesAutoresizingMaskIntoConstraints = false
    overlayView.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(imageView)
    contentView.addSubview(overlayView)

    NSLayoutConstraint.activate([
      imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
      imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      overlayView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      overlayView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      overlayView.topAnchor.constraint(equalTo: contentView.topAnchor),
      overlayView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])

    overlayView.onCTATap = { [weak self] in
      self?.onCTATap?()
    }

    applyImageContentMode()
  }

  func configure(
    slide: FKImageBannerSlide,
    imageLoader: (any FKImageLoading)?,
    animated: Bool
  ) {
    overlayView.slide = slide
    imageView.imageLoader = imageLoader

    switch slide.imageSource {
    case let .url(url, cacheKey):
      imageView.cacheKey = cacheKey
      if configuration.showsSkeletonWhileLoading {
        contentView.fk_showSkeleton(animated: true)
      }
      imageView.onStateChange = { [weak self] state in
        guard let self else { return }
        switch state {
        case .loading:
          if self.configuration.showsSkeletonWhileLoading {
            self.contentView.fk_showSkeleton(animated: true)
          }
        case .success:
          self.contentView.fk_hideSkeleton(animated: true)
        case .failure:
          self.contentView.fk_hideSkeleton(animated: true)
          self.handleFailure()
        default:
          break
        }
      }
      imageView.load(url: url, placeholder: .color(.secondarySystemFill))

    case let .image(image):
      contentView.fk_hideSkeleton(animated: false)
      imageView.setImage(image, animated: animated)

    case let .named(name, bundle):
      contentView.fk_hideSkeleton(animated: false)
      let resolved = UIImage(named: name, in: bundle, compatibleWith: traitCollection)
      imageView.setImage(resolved, animated: animated)
    }

    contentView.alpha = slide.isInteractive ? 1 : 0.85
    applyCardStyleIfNeeded()
  }

  private func applyImageContentMode() {
    switch configuration.imageContentMode {
    case .scaleAspectFill:
      imageView.configuration.appearance.contentMode = .scaleAspectFill
    case .scaleAspectFit:
      imageView.configuration.appearance.contentMode = .scaleAspectFit
    case .scaleToFill:
      imageView.configuration.appearance.contentMode = .scaleToFill
    }

    let duration = configuration.carousel.motion.imageCrossFadeDuration
    if UIAccessibility.isReduceMotionEnabled || duration <= 0 {
      imageView.configuration.appearance.successTransition = .none
    } else {
      imageView.configuration.appearance.successTransition = .crossDissolve(duration: duration)
    }

    // Card chrome is applied on `contentView`; keep the image edge-to-edge inside the cell.
    imageView.configuration.appearance.cornerStyle = .none
  }

  private func applyCardStyleIfNeeded() {
    guard let cardStyle = configuration.cardStyle else {
      contentView.layer.cornerRadius = 0
      contentView.layer.masksToBounds = true
      contentView.fk_resetCornerShadow()
      return
    }

    contentView.layer.cornerRadius = cardStyle.cornerRadius
    contentView.layer.masksToBounds = true
    if cardStyle.usesCornerShadow {
      contentView.fk_applyCornerShadow(
        corners: .allCorners,
        cornerRadius: cardStyle.cornerRadius,
        fillColor: .clear
      )
    } else {
      contentView.fk_resetCornerShadow()
    }
  }

  private func handleFailure() {
    switch configuration.failurePolicy {
    case .hideSlide:
      contentView.alpha = 0
    case .showErrorPlaceholder:
      imageView.configuration.loading.placeholder = .symbol(name: "photo", pointSize: 28, weight: .regular)
    }
  }
}
