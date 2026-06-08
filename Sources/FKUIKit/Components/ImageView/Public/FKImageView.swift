import FKCoreKit
import UIKit

/// Configuration-driven image view with placeholder, loading chrome, failure/retry, and pluggable loading.
///
/// Compose with ``FKImageLoader`` or any ``FKImageLoading`` implementation. Use ``resetForReuse()`` from cell
/// `prepareForReuse()` to avoid stale images during fast scrolling.
@MainActor
public final class FKImageView: UIView {
  /// Baseline copied by ``init(frame:)`` until replaced via ``configuration``.
  public static var defaultConfiguration: FKImageViewConfiguration {
    get { FKImageViewDefaults.defaultConfiguration }
    set { FKImageViewDefaults.defaultConfiguration = newValue }
  }

  /// Layered appearance, loading, failure, layout, accessibility, and interaction settings.
  public var configuration: FKImageViewConfiguration = FKImageViewDefaults.defaultConfiguration {
    didSet {
      applyConfiguration()
    }
  }

  /// Current load/presentation state.
  public private(set) var state: FKImageViewState = .idle {
    didSet {
      guard oldValue != state else { return }
      onStateChange?(state)
    }
  }

  /// Optional state observer.
  public var onStateChange: ((FKImageViewState) -> Void)?

  /// Remote or local URL currently bound to the view.
  public var url: URL? {
    get { currentURL }
    set { load(url: newValue) }
  }

  /// Currently displayed bitmap when ``state`` is ``FKImageViewState/success(_:)``.
  public var image: UIImage? {
    imageView.image
  }

  /// Loader used for async fetches; defaults to ``FKImageViewDefaults/sharedImageLoader``.
  public var imageLoader: (any FKImageLoading)?

  /// Optional cache key override forwarded to ``FKImageLoadRequest/cacheKey``.
  public var cacheKey: String?

  /// Optional tap handler; installs a tap recognizer when non-`nil`.
  public var onTap: (() -> Void)? {
    didSet { refreshTapGesture() }
  }

  // MARK: - Subviews

  let contentContainer = UIView()
  let imageView = UIImageView()
  var placeholderView: FKImageViewPlaceholderView?
  var failureView: FKImageViewFailureView?
  var activityIndicator: UIActivityIndicatorView?
  var progressBar: FKProgressBar?

  // MARK: - Private state

  var currentURL: URL?
  var explicitPlaceholder: FKImageViewPlaceholder?
  var lastResolvedTargetSize: CGSize = .zero
  var isPausedOffscreen = false
  var wasLoadingWhenPausedOffscreen = false
  var lastRetryDate: Date?
  let loadCoordinator = FKImageViewLoadCoordinator()
  var tapRecognizer: UITapGestureRecognizer?
  var pressRecognizer: UILongPressGestureRecognizer?
  var progressBarHeightConstraint: NSLayoutConstraint?

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Creates a view with an explicit configuration.
  public convenience init(configuration: FKImageViewConfiguration) {
    self.init(frame: .zero)
    self.configuration = configuration
  }

  /// Creates a view using a preset ``FKImageViewProfile``.
  public convenience init(profile: FKImageViewProfile) {
    self.init(configuration: .profile(profile))
  }

  public override var contentMode: UIView.ContentMode {
    get { configuration.appearance.contentMode }
    set {
      configuration.appearance.contentMode = newValue
      imageView.contentMode = newValue
    }
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    applyCornerAndBorderStyles()
    reloadIfBoundsChangedSignificantly()
  }

  public override func setContentHuggingPriority(_ priority: UILayoutPriority, for axis: NSLayoutConstraint.Axis) {
    super.setContentHuggingPriority(priority, for: axis)
    imageView.setContentHuggingPriority(priority, for: axis)
  }

  public override func setContentCompressionResistancePriority(
    _ priority: UILayoutPriority,
    for axis: NSLayoutConstraint.Axis
  ) {
    super.setContentCompressionResistancePriority(priority, for: axis)
    imageView.setContentCompressionResistancePriority(priority, for: axis)
  }

  public override var intrinsicContentSize: CGSize {
    if let image = imageView.image {
      return image.size
    }
    if let hint = configuration.layout.intrinsicPlaceholderSize {
      return hint
    }
    return CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
  }

  public override func willMove(toWindow newWindow: UIWindow?) {
    super.willMove(toWindow: newWindow)
    guard configuration.loading.pausesLoadingWhenOffscreen else { return }
    if newWindow == nil {
      isPausedOffscreen = true
      wasLoadingWhenPausedOffscreen = state == .loading
      loadCoordinator.resetIdentity()
      hideLoadingChrome()
      if wasLoadingWhenPausedOffscreen {
        transitionToPlaceholderOnly()
      }
    } else if isPausedOffscreen {
      isPausedOffscreen = false
      defer { wasLoadingWhenPausedOffscreen = false }
      guard wasLoadingWhenPausedOffscreen, let currentURL else { return }
      performLoad(url: currentURL, ignoringMemoryCache: false)
    }
  }

  // MARK: - Public API

  /// Applies a full configuration value.
  public func apply(_ configuration: FKImageViewConfiguration) {
    self.configuration = configuration
  }

  /// Applies a configuration mutation block.
  public func apply(_ block: (inout FKImageViewConfiguration) -> Void) {
    var next = configuration
    block(&next)
    configuration = next
  }

  /// Sets `url`, optional per-load placeholder bitmap, and starts loading when ``FKImageViewLoadingConfiguration/loadsAutomatically`` is `true`.
  public func load(url: URL?, placeholder: UIImage? = nil) {
    if let placeholder {
      explicitPlaceholder = .image(placeholder)
    } else {
      explicitPlaceholder = nil
    }
    bindURL(url, startLoadIfNeeded: configuration.loading.loadsAutomatically)
  }

  /// Sets `url`, optional typed placeholder, and starts loading when ``FKImageViewLoadingConfiguration/loadsAutomatically`` is `true`.
  public func load(url: URL?, placeholder: FKImageViewPlaceholder?) {
    explicitPlaceholder = placeholder
    bindURL(url, startLoadIfNeeded: configuration.loading.loadsAutomatically)
  }

  /// Starts loading ``url`` when ``FKImageViewLoadingConfiguration/loadsAutomatically`` is `false`.
  public func startLoading() {
    guard let url = currentURL else { return }
    performLoad(url: url, ignoringMemoryCache: false)
  }

  /// Displays a local image without URL binding or network I/O.
  public func setImage(_ image: UIImage?, animated: Bool = true) {
    loadCoordinator.resetIdentity()
    hideLoadingChrome()
    releaseFailureView()
    currentURL = nil
    explicitPlaceholder = nil
    guard let image else {
      reset()
      return
    }
    let rendered = renderedImage(image)
    displayImage(rendered, animated: animated)
    setState(.success(rendered))
    invalidateIntrinsicContentSize()
    updateAccessibility()
  }

  /// Cancels the in-flight load for the current request.
  public func cancelLoad() {
    guard let url = currentURL else {
      loadCoordinator.resetIdentity()
      hideLoadingChrome()
      releaseFailureView()
      releasePlaceholderView()
      setState(.idle)
      return
    }
    let request = currentRequest(for: url)
    let loader = resolvedLoader()
    loadCoordinator.cancelLoad(loader: loader, request: request)
    hideLoadingChrome()
    if currentURL != nil {
      transitionToPlaceholderOnly()
    } else {
      setState(.idle)
    }
  }

  /// Re-fetches the current URL, skipping the memory cache read while still allowing disk/network per loader policy.
  public func reload() {
    guard let url = currentURL else { return }
    performLoad(url: url, ignoringMemoryCache: true)
  }

  /// Clears URL, image, overlays, and returns to ``FKImageViewState/idle``.
  public func reset() {
    currentURL = nil
    explicitPlaceholder = nil
    loadCoordinator.resetIdentity()
    hideLoadingChrome()
    releaseFailureView()
    imageView.image = nil
    imageView.alpha = 1
    releasePlaceholderView()
    if configuration.loading.showsPlaceholderWhenIdle {
      updatePlaceholderPresentation(for: .idle)
    }
    setState(.idle)
    invalidateIntrinsicContentSize()
    updateAccessibility()
  }

  /// Cell-reuse helper: cancels loads and clears transient UI without changing configuration.
  public func resetForReuse() {
    loadCoordinator.resetIdentity()
    hideLoadingChrome()
    releaseFailureView()
    imageView.image = nil
    imageView.alpha = 1
    currentURL = nil
    explicitPlaceholder = nil
    lastResolvedTargetSize = .zero
    isPausedOffscreen = false
    wasLoadingWhenPausedOffscreen = false
    lastRetryDate = nil
    updatePlaceholderPresentation(for: .idle)
    setState(.idle)
    invalidateIntrinsicContentSize()
    updateAccessibility()
  }

  /// Retries the current URL when ``FKImageViewFailureConfiguration/isRetryEnabled`` is `true`.
  public func retry() {
    guard configuration.failure.isRetryEnabled, let url = currentURL else { return }
    if let lastRetryDate,
      Date().timeIntervalSince(lastRetryDate) < configuration.interaction.retryDebounceInterval
    {
      return
    }
    lastRetryDate = Date()
    performLoad(
      url: url,
      ignoringMemoryCache: configuration.failure.retryIgnoresMemoryCache
    )
  }

  func setState(_ newState: FKImageViewState) {
    state = newState
  }
}
