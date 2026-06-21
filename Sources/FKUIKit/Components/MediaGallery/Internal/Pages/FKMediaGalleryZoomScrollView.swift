import UIKit

/// Zoomable scroll container for image pages.
@MainActor
final class FKMediaGalleryZoomScrollView: UIScrollView, UIScrollViewDelegate {
  private let lightweightImageView: UIImageView = {
    let view = UIImageView()
    view.contentMode = .scaleAspectFit
    return view
  }()
  private var remoteImageView: FKImageView?
  private var configuration = FKMediaGalleryZoomConfiguration()
  private var doubleTapRecognizer: UITapGestureRecognizer?
  private var lastLayoutBoundsSize: CGSize = .zero
  private var lastImagePixelSize: CGSize = .zero
  private var usesRemoteImageView = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    delegate = self
    showsHorizontalScrollIndicator = false
    showsVerticalScrollIndicator = false
    bouncesZoom = true
    backgroundColor = .clear
    minimumZoomScale = 1
    maximumZoomScale = 4
    delaysContentTouches = false
    canCancelContentTouches = true
    addSubview(lightweightImageView)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    let imagePixelSize = FKMediaGalleryLayoutMath.resolvedImageSize(from: displayedImage)
    let boundsChanged = bounds.size != lastLayoutBoundsSize
    let imageChanged = imagePixelSize != lastImagePixelSize
    if boundsChanged || imageChanged {
      lastLayoutBoundsSize = bounds.size
      lastImagePixelSize = imagePixelSize
      updateImageViewFrameForCurrentBounds()
      if boundsChanged, isZoomedBeyondMinimum {
        setZoomScale(minimumZoomScale, animated: false)
      }
    }
    centerImageIfNeeded()
    alignMinimumZoomContentOffsetIfNeeded()
    updateScrollInteractionState()
  }

  /// Remote-loading image view; created lazily when URL or photo-library sources are used.
  var fkImageView: FKImageView {
    ensureRemoteImageView()
  }

  func apply(configuration: FKMediaGalleryZoomConfiguration) {
    self.configuration = configuration
    minimumZoomScale = configuration.minimumZoomScale
    maximumZoomScale = configuration.maximumZoomScale
    zoomScale = configuration.minimumZoomScale
    refreshDoubleTapGesture()
    setNeedsLayout()
  }

  func configureImageLoader(_ loader: (any FKImageLoading)?) {
    remoteImageView?.imageLoader = loader
  }

  func setLocalImage(_ image: UIImage?) {
    switchToLightweightDisplay()
    lightweightImageView.image = image
    relayoutForNewImage()
  }

  func resetZoom(animated: Bool) {
    setZoomScale(configuration.minimumZoomScale, animated: animated)
    centerImageIfNeeded()
    alignMinimumZoomContentOffsetIfNeeded()
    updateScrollInteractionState()
  }

  func resetContent() {
    releaseDisplayedImage(clearRemoteView: true)
  }

  /// Drops decoded bitmaps and cancels in-flight remote loads while keeping zoom configuration.
  func releaseDisplayedImage(clearRemoteView: Bool = false) {
    remoteImageView?.cancelLoad()
    remoteImageView?.resetForReuse()
    lightweightImageView.image = nil
    lastImagePixelSize = .zero
    resetZoom(animated: false)
    if clearRemoteView {
      remoteImageView?.removeFromSuperview()
      remoteImageView = nil
      usesRemoteImageView = false
      if lightweightImageView.superview == nil {
        addSubview(lightweightImageView)
      }
    }
  }

  func relayoutForNewImage() {
    lastImagePixelSize = .zero
    setNeedsLayout()
    layoutIfNeeded()
  }

  var isZoomedBeyondMinimum: Bool {
    zoomScale > configuration.minimumZoomScale + 0.05
  }

  /// Whether a bitmap is currently mounted in the zoom target.
  var hasDisplayedImage: Bool {
    guard let image = displayedImage else { return false }
    return image.size.width > 0 && image.size.height > 0
  }

  /// Image shown in the zoom view, for interactive dismiss.
  var dismissVisualImage: UIImage? {
    displayedImage
  }

  // MARK: - UIScrollViewDelegate

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    zoomTargetView
  }

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    centerImageIfNeeded()
    updateScrollInteractionState()
  }

  func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
    if scale <= configuration.minimumZoomScale + 0.05 {
      setZoomScale(configuration.minimumZoomScale, animated: true)
      centerImageIfNeeded()
      alignMinimumZoomContentOffsetIfNeeded()
    }
    updateScrollInteractionState()
  }

  // MARK: - Double tap

  private func refreshDoubleTapGesture() {
    if let doubleTapRecognizer {
      removeGestureRecognizer(doubleTapRecognizer)
    }
    doubleTapRecognizer = nil
    guard configuration.allowsDoubleTap else { return }
    let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
    recognizer.numberOfTapsRequired = 2
    addGestureRecognizer(recognizer)
    doubleTapRecognizer = recognizer
  }

  @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
    if isZoomedBeyondMinimum {
      setZoomScale(configuration.minimumZoomScale, animated: true)
      return
    }
    let targetScale = min(configuration.doubleTapZoomScale, maximumZoomScale)
    if configuration.doubleTapZoomsToFocalPoint {
      let point = recognizer.location(in: zoomTargetView)
      let zoomRect = zoomRect(for: targetScale, centeredAt: point)
      zoom(to: zoomRect, animated: true)
    } else {
      setZoomScale(targetScale, animated: true)
    }
  }

  private func zoomRect(for scale: CGFloat, centeredAt point: CGPoint) -> CGRect {
    let size = CGSize(
      width: bounds.width / scale,
      height: bounds.height / scale
    )
    let origin = CGPoint(
      x: point.x - size.width * 0.5,
      y: point.y - size.height * 0.5
    )
    return CGRect(origin: origin, size: size)
  }

  private var zoomTargetView: UIView {
    usesRemoteImageView ? ensureRemoteImageView() : lightweightImageView
  }

  private var displayedImage: UIImage? {
    if usesRemoteImageView {
      return remoteImageView?.image
    }
    return lightweightImageView.image
  }

  private func switchToLightweightDisplay() {
    guard usesRemoteImageView else { return }
    remoteImageView?.cancelLoad()
    remoteImageView?.removeFromSuperview()
    remoteImageView = nil
    usesRemoteImageView = false
    if lightweightImageView.superview == nil {
      addSubview(lightweightImageView)
    }
    zoomScale = configuration.minimumZoomScale
  }

  private func ensureRemoteImageView() -> FKImageView {
    if let remoteImageView {
      return remoteImageView
    }
    lightweightImageView.removeFromSuperview()
    lightweightImageView.image = nil
    var imageConfiguration = FKImageViewConfiguration.profile(.full)
    imageConfiguration.appearance.contentMode = .scaleAspectFit
    imageConfiguration.loading.pausesLoadingWhenOffscreen = true
    let view = FKImageView(configuration: imageConfiguration)
    addSubview(view)
    remoteImageView = view
    usesRemoteImageView = true
    zoomScale = configuration.minimumZoomScale
    return view
  }

  /// Lays out the zoom target at the origin; centering is handled via `contentInset`.
  private func updateImageViewFrameForCurrentBounds() {
    let target = zoomTargetView
    let imagePixelSize = FKMediaGalleryLayoutMath.resolvedImageSize(from: displayedImage)
    let fittedSize: CGSize
    if imagePixelSize.width > 0,
       imagePixelSize.height > 0,
       bounds.width > 0,
       bounds.height > 0 {
      let scale = min(bounds.width / imagePixelSize.width, bounds.height / imagePixelSize.height)
      fittedSize = CGSize(width: imagePixelSize.width * scale, height: imagePixelSize.height * scale)
    } else {
      fittedSize = bounds.size
    }
    target.frame = CGRect(origin: .zero, size: fittedSize)
    contentSize = fittedSize
  }

  private func centerImageIfNeeded() {
    let target = zoomTargetView
    let scaledWidth = target.frame.width * zoomScale
    let scaledHeight = target.frame.height * zoomScale
    let offsetX = max((bounds.width - scaledWidth) * 0.5, 0)
    let offsetY = max((bounds.height - scaledHeight) * 0.5, 0)
    contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: offsetY, right: offsetX)
  }

  /// Pairs with `contentInset` centering so aspect-fit images stay vertically centered at minimum zoom.
  private func alignMinimumZoomContentOffsetIfNeeded() {
    guard !isZoomedBeyondMinimum else { return }
    let target = CGPoint(x: -contentInset.left, y: -contentInset.top)
    if abs(contentOffset.x - target.x) > 0.5 || abs(contentOffset.y - target.y) > 0.5 {
      contentOffset = target
    }
  }

  /// At minimum zoom the inner scroll view must not steal horizontal pans from the gallery pager.
  private func updateScrollInteractionState() {
    isScrollEnabled = isZoomedBeyondMinimum
    pinchGestureRecognizer?.isEnabled = true
  }

  func cancelRemoteLoading() {
    remoteImageView?.cancelLoad()
  }
}

import FKCoreKit
