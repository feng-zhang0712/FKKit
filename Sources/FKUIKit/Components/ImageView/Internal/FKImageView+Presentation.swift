import FKCoreKit
import UIKit

extension FKImageView {
  func commonInit() {
    clipsToBounds = false
    isAccessibilityElement = true
    accessibilityTraits = .image

    contentContainer.clipsToBounds = true
    contentContainer.translatesAutoresizingMaskIntoConstraints = false
    addSubview(contentContainer)

    imageView.clipsToBounds = true
    imageView.translatesAutoresizingMaskIntoConstraints = false

    contentContainer.addSubview(imageView)

    NSLayoutConstraint.activate([
      contentContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
      contentContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
      contentContainer.topAnchor.constraint(equalTo: topAnchor),
      contentContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

      imageView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
      imageView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
      imageView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
    ])

    applyConfiguration()
  }

  func applyConfiguration() {
    let appearance = configuration.appearance
    backgroundColor = appearance.backgroundColor
    imageView.contentMode = appearance.contentMode
    imageView.tintColor = appearance.tintColor
    contentContainer.backgroundColor = appearance.backgroundColor
    updatePlaceholderPresentation()
    applyCornerAndBorderStyles()
    applyShadowStyle()
    updateLoadingChromeVisibility()
    refreshTapGesture()
    updateAccessibility()
    setNeedsLayout()
  }

  func bindURL(_ url: URL?, startLoadIfNeeded: Bool) {
    currentURL = url
    if url == nil {
      reset()
      return
    }
    guard startLoadIfNeeded else {
      transitionToPlaceholderOnly()
      return
    }
    performLoad(url: url!, ignoringMemoryCache: false)
  }

  func updatePlaceholderPresentation(for state: FKImageViewState? = nil) {
    let resolvedState = state ?? self.state
    guard shouldShowPlaceholderLayer(for: resolvedState) else {
      releasePlaceholderView()
      return
    }
    let view = ensurePlaceholderView()
    if let provider = configuration.loading.customPlaceholderProvider {
      view.setCustomContent(provider())
      return
    }
    view.clearCustomContent()
    view.apply(placeholder: activePlaceholder())
    view.isHidden = false
  }

  func shouldShowPlaceholderLayer(for state: FKImageViewState) -> Bool {
    if configuration.loading.customPlaceholderProvider != nil { return true }
    switch state {
    case .idle:
      return configuration.loading.showsPlaceholderWhenIdle
    case .placeholder, .loading:
      if case .none = activePlaceholder() { return false }
      return true
    case .success:
      return false
    case .failure:
      guard !configuration.failure.showsFailureOverlay else { return false }
      if case .none = activePlaceholder() { return false }
      return true
    }
  }

  func resolvedLoader() -> any FKImageLoading {
    imageLoader ?? FKImageViewDefaults.sharedImageLoader
  }

  func activePlaceholder() -> FKImageViewPlaceholder {
    explicitPlaceholder ?? configuration.loading.placeholder
  }

  func currentRequest(for url: URL) -> FKImageLoadRequest {
    FKImageViewRequestFactory.makeRequest(
      url: url,
      targetSizePolicy: configuration.loading.targetSizePolicy,
      bounds: bounds,
      screenScale: traitCollection.displayScale,
      cacheKey: cacheKey
    )
  }

  func loadOptions(ignoringMemoryCache: Bool) -> FKImageLoadOptions {
    var options = FKImageLoadOptions()
    options.cachePolicy = ignoringMemoryCache ? .reloadIgnoringCache : configuration.loading.cachePolicy
    options.excludesFromDiskCache = configuration.loading.excludesFromDiskCache
    return options
  }

  func cancelInFlightLoadIfNeeded(for url: URL) {
    guard let identity = loadCoordinator.identity else { return }
    let loader = resolvedLoader()
    let previousRequest = FKImageViewRequestFactory.makeRequest(from: identity, cacheKey: cacheKey)
    loader.cancelLoad(for: previousRequest)
    if identity.url != url {
      FKImageViewLogging.debug("Cancelled in-flight load for \(identity.url.absoluteString)")
    }
    loadCoordinator.resetIdentity()
  }

  func performLoad(url: URL, ignoringMemoryCache: Bool) {
    cancelInFlightLoadIfNeeded(for: url)
    let request = currentRequest(for: url)
    lastResolvedTargetSize = resolvedTargetSize(from: request)
    let loader = resolvedLoader()
    let options = loadOptions(ignoringMemoryCache: ignoringMemoryCache)

    if !ignoringMemoryCache,
      case .success(let image) = state,
      currentURL == url
    {
      presentSuccessImage(image, animated: false)
      return
    }

    if !ignoringMemoryCache,
      let cached = FKImageViewRequestFactory.cachedPreview(
        for: request,
        loader: loader,
        enabled: configuration.loading.checksMemoryCachePreview
      )
    {
      presentSuccessImage(cached, animated: false)
      return
    }

    transitionToPlaceholderOnly()
    showLoadingChrome()

    loadCoordinator.start(
      request: request,
      loader: loader,
      options: options,
      onState: { [weak self] state in
        self?.setState(state)
      },
      onSuccess: { [weak self] image, identity in
        self?.applySuccessImage(image, identity: identity)
      },
      onFailure: { [weak self] reason, identity in
        self?.applyFailure(reason: reason, identity: identity)
      }
    )
  }

  func transitionToPlaceholderOnly() {
    releaseFailureView()
    imageView.image = nil
    updatePlaceholderPresentation(for: .placeholder)
    setState(.placeholder)
  }

  func renderedImage(_ image: UIImage) -> UIImage {
    configuration.appearance.rendersAsTemplate
      ? image.withRenderingMode(.alwaysTemplate)
      : image
  }

  func presentSuccessImage(_ image: UIImage, animated: Bool) {
    hideLoadingChrome()
    releaseFailureView()
    let rendered = renderedImage(image)
    displayImage(rendered, animated: animated)
    setState(.success(rendered))
    invalidateIntrinsicContentSize()
    updateAccessibility()
    if configuration.accessibility.announcesLayoutChangeOnSuccess {
      UIAccessibility.post(notification: .layoutChanged, argument: self)
    }
    refreshTapGesture()
  }

  func displayImage(_ image: UIImage, animated: Bool) {
    releasePlaceholderView()

    guard animated else {
      imageView.alpha = 1
      imageView.image = image
      return
    }

    switch resolvedSuccessTransition() {
    case .none:
      imageView.alpha = 1
      imageView.image = image
    case .crossDissolve(let duration):
      UIView.transition(
        with: contentContainer,
        duration: duration,
        options: [.transitionCrossDissolve, .allowUserInteraction]
      ) {
        self.imageView.image = image
      }
    case .fadeIn(let duration):
      imageView.image = image
      imageView.alpha = 0
      UIView.animate(withDuration: duration) {
        self.imageView.alpha = 1
      }
    }
  }

  func applySuccessImage(_ image: UIImage, identity: FKImageViewLoadCoordinator.Identity) {
    guard loadCoordinator.identity == identity else {
      FKImageViewLogging.debug("Discarded success due to identity mismatch for \(identity.url.absoluteString)")
      return
    }
    presentSuccessImage(image, animated: true)
  }

  func applyFailure(reason: FKImageViewFailureReason, identity: FKImageViewLoadCoordinator.Identity) {
    guard loadCoordinator.identity == identity else {
      FKImageViewLogging.debug("Discarded failure due to identity mismatch for \(identity.url.absoluteString)")
      return
    }
    hideLoadingChrome()
    imageView.image = nil
    if configuration.failure.showsFailureOverlay {
      releasePlaceholderView()
      let overlay = ensureFailureView()
      overlay.apply(configuration: configuration.failure, reason: reason)
      overlay.isHidden = false
    } else {
      releaseFailureView()
      updatePlaceholderPresentation(for: .failure(reason))
    }
    setState(.failure(reason))
    updateAccessibility()
    refreshTapGesture()
  }

  func resolvedSuccessTransition() -> FKImageViewSuccessTransition {
    if UIAccessibility.isReduceMotionEnabled {
      return .none
    }
    return configuration.appearance.successTransition
  }

  func resolvedTargetSize(from request: FKImageLoadRequest) -> CGSize {
    CGSize(
      width: CGFloat(request.targetWidth ?? 0),
      height: CGFloat(request.targetHeight ?? 0)
    )
  }

  func reloadIfBoundsChangedSignificantly() {
    guard configuration.loading.targetSizePolicy == .automaticFromBounds,
      let url = currentURL,
      configuration.loading.loadsAutomatically,
      bounds.width > 0,
      bounds.height > 0
    else { return }

    let request = currentRequest(for: url)
    let nextSize = resolvedTargetSize(from: request)
    guard lastResolvedTargetSize != .zero else {
      lastResolvedTargetSize = nextSize
      return
    }
    let threshold = configuration.loading.boundsChangeReloadThreshold
    let widthDelta = abs(nextSize.width - lastResolvedTargetSize.width) / max(lastResolvedTargetSize.width, 1)
    let heightDelta = abs(nextSize.height - lastResolvedTargetSize.height) / max(lastResolvedTargetSize.height, 1)
    if widthDelta > threshold || heightDelta > threshold {
      lastResolvedTargetSize = nextSize
      performLoad(url: url, ignoringMemoryCache: false)
    }
  }
}
