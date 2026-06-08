import FKCoreKit
import UIKit

/// Image-first marketing / feed hero carousel built on ``FKCarousel``.
///
/// Maps ``FKImageBannerSlide`` models to carousel pages with ``FKImageView`` loading, overlay text, and CTA handling.
@MainActor
public final class FKImageBanner: UIView {
  /// Shared default configuration.
  public static var defaultConfiguration: FKImageBannerConfiguration {
    get { FKCarouselDefaults.imageBannerConfiguration }
    set { FKCarouselDefaults.imageBannerConfiguration = newValue }
  }

  /// Image-banner configuration mapped to the internal carousel.
  public var configuration: FKImageBannerConfiguration = FKCarouselDefaults.imageBannerConfiguration {
    didSet {
      guard configuration != oldValue else { return }
      applyConfiguration()
    }
  }

  /// Optional delegate.
  public weak var delegate: FKImageBannerDelegate?

  /// Closure callbacks alternative to the delegate.
  public var callbacks = FKImageBannerCallbacks()

  /// Injected image loader; defaults to ``FKImageLoader/shared``.
  public var imageLoader: (any FKImageLoading)?

  /// Current slides.
  public private(set) var slides: [FKImageBannerSlide] = []

  /// Logical settled slide index.
  public var currentSlideIndex: Int {
    carousel.currentPageIndex
  }

  private let carousel = FKCarousel()
  private var prefetchTask: Task<Void, Never>?

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public convenience init(
    configuration: FKImageBannerConfiguration = FKCarouselDefaults.imageBannerConfiguration,
    slides: [FKImageBannerSlide] = []
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    setSlides(slides, preservingIndex: false)
  }

  public override var intrinsicContentSize: CGSize {
    carousel.intrinsicContentSize
  }

  public override func systemLayoutSizeFitting(
    _ targetSize: CGSize,
    withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
    verticalFittingPriority: UILayoutPriority
  ) -> CGSize {
    carousel.systemLayoutSizeFitting(
      targetSize,
      withHorizontalFittingPriority: horizontalFittingPriority,
      verticalFittingPriority: verticalFittingPriority
    )
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    guard configuration.overlayExpansionPolicy == .growBanner else { return }
    if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
      refreshOverlayDrivenLayout()
    }
  }

  // MARK: - Public API

  /// Applies configuration while preserving the current slide when possible.
  public func apply(configuration: FKImageBannerConfiguration) {
    self.configuration = configuration
  }

  /// Replaces all slides.
  public func setSlides(_ newSlides: [FKImageBannerSlide], preservingIndex: Bool = true) {
    slides = newSlides
    carousel.setItems(newSlides.map(\.carouselItem), animated: false, preservingIndex: preservingIndex)
    prefetchNeighbors(around: carousel.currentPageIndex)
    refreshOverlayDrivenLayout()
  }

  /// Reloads a single slide by identifier.
  public func reloadSlide(id: String) {
    guard let index = slides.firstIndex(where: { $0.id == id }) else { return }
    carousel.collectionView.reloadItems(at: [IndexPath(item: carouselPageIndex(forLogical: index), section: 0)])
  }

  /// Scrolls to a slide index.
  public func scrollToSlide(_ index: Int, animated: Bool) {
    carousel.scrollToPage(index, animated: animated)
  }

  // MARK: - Private

  private func commonInit() {
    backgroundColor = .clear
    addSubview(carousel)
    carousel.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      carousel.leadingAnchor.constraint(equalTo: leadingAnchor),
      carousel.trailingAnchor.constraint(equalTo: trailingAnchor),
      carousel.topAnchor.constraint(equalTo: topAnchor),
      carousel.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    carousel.customCellProvider = { [weak self] collectionView, indexPath, logicalIndex in
      guard let self else {
        return UICollectionViewCell()
      }
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: FKImageBannerPageCell.reuseIdentifier,
        for: indexPath
      ) as! FKImageBannerPageCell

      guard let slide = self.slides[safe: logicalIndex] else { return cell }

      cell.configuration = self.configuration
      cell.onCTATap = { [weak self] in
        self?.handleCTATap(at: logicalIndex)
      }
      cell.configure(
        slide: slide,
        imageLoader: self.imageLoader ?? FKImageLoader.shared,
        animated: !UIAccessibility.isReduceMotionEnabled
      )

      let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleSlideTap(_:)))
      tap.cancelsTouchesInView = false
      cell.contentView.gestureRecognizers?
        .filter { $0 is UITapGestureRecognizer }
        .forEach { cell.contentView.removeGestureRecognizer($0) }
      cell.contentView.addGestureRecognizer(tap)
      cell.contentView.tag = logicalIndex

      return cell
    }

    carousel.delegate = self
    carousel.collectionView.register(
      FKImageBannerPageCell.self,
      forCellWithReuseIdentifier: FKImageBannerPageCell.reuseIdentifier
    )

    applyConfiguration()
  }

  private func applyConfiguration() {
    var carouselConfig = configuration.carousel
    if configuration.overlayExpansionPolicy == .growBanner {
      carouselConfig.layout.heightStrategy = .intrinsicFromCurrentPage
      carousel.intrinsicPageHeightResolver = { [weak self] pageWidth in
        self?.resolvedPageHeight(forPageWidth: pageWidth) ?? 0
      }
    } else {
      carousel.intrinsicPageHeightResolver = nil
    }

    carousel.apply(configuration: carouselConfig)
    invalidateBannerLayout()
  }

  private func resolvedPageHeight(forPageWidth pageWidth: CGFloat) -> CGFloat {
    let baseHeight = FKCarouselLayoutEngine.resolvedHeight(
      width: pageWidth,
      strategy: configuration.carousel.layout.heightStrategy
    )
    guard baseHeight > 0 else { return 0 }

    let slide = slides[safe: currentSlideIndex]
    let extra = FKImageBannerOverlayMetrics.additionalBannerHeight(
      slide: slide,
      configuration: configuration,
      pageWidth: pageWidth,
      traitCollection: traitCollection
    )
    return baseHeight + extra
  }

  private func invalidateBannerLayout() {
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    carousel.invalidateIntrinsicContentSize()
    carousel.setNeedsLayout()
  }

  private func refreshOverlayDrivenLayout() {
    guard configuration.overlayExpansionPolicy == .growBanner else { return }
    invalidateBannerLayout()
  }

  private func carouselPageIndex(forLogical index: Int) -> Int {
    let adapter = FKCarouselInfiniteLoopAdapter(
      isEnabled: configuration.carousel.layout.isInfiniteLoopEnabled,
      logicalCount: slides.count
    )
    return adapter.physicalIndex(forLogical: index)
  }

  private func handleSlideSelection(at index: Int) {
    guard let slide = slides[safe: index], slide.isInteractive else { return }
    delegate?.imageBanner(self, didSelectSlideAt: index)
    callbacks.onSlideTap?(index)
    openLinkIfNeeded(for: slide, at: index)
  }

  private func handleCTATap(at index: Int) {
    delegate?.imageBanner(self, didTapCTAForSlideAt: index)
    callbacks.onCTATap?(index)

    guard
      configuration.ctaUsesLinkURL,
      let slide = slides[safe: index],
      let url = slide.linkURL
    else { return }

    openURL(url, for: slide, at: index)
  }

  @objc private func handleSlideTap(_ recognizer: UITapGestureRecognizer) {
    guard let view = recognizer.view else { return }
    handleSlideSelection(at: view.tag)
  }

  private func openLinkIfNeeded(for slide: FKImageBannerSlide, at index: Int) {
    guard let url = slide.linkURL else { return }
    switch slide.linkOpenPolicy {
    case .callbackOnly:
      return
    case .inAppSafari, .openSystem:
      openURL(url, for: slide, at: index)
    }
  }

  private func openURL(_ url: URL, for slide: FKImageBannerSlide, at index: Int) {
    guard isAllowedLink(url) else { return }
    let allowed = delegate?.imageBanner(self, shouldOpenLink: url, forSlideAt: index)
      ?? callbacks.onShouldOpenLink?(url, index)
      ?? true
    guard allowed else { return }

    switch slide.linkOpenPolicy {
    case .callbackOnly:
      break
    case .openSystem:
      UIApplication.shared.open(url)
    case .inAppSafari:
      UIApplication.shared.open(url)
    }
  }

  private func isAllowedLink(_ url: URL) -> Bool {
    guard let scheme = url.scheme?.lowercased() else { return false }
    let defaults: Set<String> = ["http", "https", "tel"]
    return defaults.contains(scheme) || configuration.allowedLinkSchemes.contains(scheme)
  }

  private func prefetchNeighbors(around index: Int) {
    prefetchTask?.cancel()
    let radius = max(0, configuration.prefetchRadius)
    guard radius > 0 else { return }

    prefetchTask = Task { @MainActor [weak self] in
      guard let self else { return }
      let prefetchLoader = (self.imageLoader as? FKImageLoader) ?? FKImageLoader.shared
      let targetSize = self.carousel.bounds.size
      let resolvedTargetSize = targetSize.width > 0 && targetSize.height > 0 ? targetSize : nil
      var requests: [FKImageLoadRequest] = []

      for offset in (-radius)...radius where offset != 0 {
        let neighbor = index + offset
        guard neighbor >= 0, neighbor < self.slides.count else { continue }
        guard case let .url(url, cacheKey) = self.slides[neighbor].imageSource else { continue }
        requests.append(FKImageLoadRequest(url: url, targetSize: resolvedTargetSize, cacheKey: cacheKey))
      }

      for request in requests {
        guard !Task.isCancelled else { return }
        await prefetchLoader.prefetch(request)
      }
    }
  }
}

extension FKImageBanner: FKCarouselDelegate {
  public func carousel(_ carousel: FKCarousel, didScrollToPage index: Int, reason: FKCarouselPageChangeReason) {
    delegate?.imageBanner(self, didScrollToSlide: index, reason: reason)
    callbacks.onSlideChanged?(index, reason)
    prefetchNeighbors(around: index)
    refreshOverlayDrivenLayout()
  }

  public func carousel(_ carousel: FKCarousel, didSelectPageAt index: Int) {
    handleSlideSelection(at: index)
  }
}
