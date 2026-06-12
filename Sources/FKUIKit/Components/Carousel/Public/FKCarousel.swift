import UIKit

/// Generic horizontal paging carousel backed by `UICollectionView`.
///
/// Supply pages via ``dataSource`` or ``pageProvider``. Configure layout, indicator, and auto-scroll through
/// ``configuration``. For image-first marketing banners, prefer ``FKImageBanner``.
@MainActor
public final class FKCarousel: UIView {
  /// Shared default configuration.
  public static var defaultConfiguration: FKCarouselConfiguration {
    get { FKCarouselDefaults.configuration }
    set { FKCarouselDefaults.configuration = newValue }
  }

  /// Layered carousel configuration.
  public var configuration: FKCarouselConfiguration = FKCarouselDefaults.configuration {
    didSet {
      guard configuration != oldValue else { return }
      applyConfigurationChanges()
    }
  }

  /// Optional data source for custom page views.
  public weak var dataSource: FKCarouselDataSource?

  /// Optional delegate.
  public weak var delegate: FKCarouselDelegate?

  /// Closure callbacks alternative to the delegate.
  public var callbacks = FKCarouselCallbacks()

  /// Closure-based page builder for lightweight hosts.
  public var pageProvider: ((FKCarouselItem, CGRect) -> UIView)?

  /// Optional custom cell provider used by ``FKImageBanner`` and advanced hosts.
  var customCellProvider: ((UICollectionView, IndexPath, Int) -> UICollectionViewCell)?

  /// Resolves page height when ``FKCarouselHeightStrategy/intrinsicFromCurrentPage`` is active.
  var intrinsicPageHeightResolver: ((CGFloat) -> CGFloat)?

  /// Host renderer invoked for ``FKCarouselIndicatorStyle/custom(id:)``.
  ///
  /// - Parameters:
  ///   - container: Dedicated host container; add subviews here only.
  ///   - pageCount: Logical page count.
  ///   - progress: Overall position in `0...1`, equivalent to ``FKCarouselIndicatorStyle/bar`` fill
  ///     (`(effectivePage + 1) / pageCount` when ``FKCarouselIndicatorConfiguration/indicatorFollowsScrollProgress``
  ///     is enabled; `(currentPage + 1) / pageCount` when disabled).
  public var customIndicatorRenderer: ((UIView, Int, CGFloat) -> Void)? {
    didSet {
      indicatorView?.customRenderer = customIndicatorRenderer
    }
  }

  /// Logical page items.
  public private(set) var items: [FKCarouselItem] = []

  /// Logical settled page index (`0 ..< pageCount`).
  public private(set) var currentPageIndex: Int = 0

  /// Number of logical pages.
  public var pageCount: Int { items.count }

  /// Read-only runtime snapshot.
  public private(set) var stateSnapshot = FKCarouselStateSnapshot()

  /// Fractional scroll progress within the current page span.
  public private(set) var scrollProgress: CGFloat = 0

  /// Exposed pan gesture for advanced host wiring.
  public var panGestureRecognizer: UIPanGestureRecognizer {
    collectionView.panGestureRecognizer
  }

  let collectionView: UICollectionView
  private let flowLayout = FKCarouselFlowLayout()
  private var indicatorView: FKCarouselPageIndicatorView?
  private let autoScrollController = FKCarouselAutoScrollController()
  private let gestureCoordinator = FKCarouselGestureCoordinator()

  private var metrics = FKCarouselLayoutEngine.Metrics(
    pageWidth: 0,
    pageHeight: 0,
    itemSize: .zero,
    sectionInset: .zero,
    pageSpan: 0,
    collectionHeight: 0,
    indicatorSpacing: 0,
    usesPagingEnabled: true
  )

  private var loopAdapter = FKCarouselInfiniteLoopAdapter(isEnabled: false, logicalCount: 0)
  private var hostedViews: [Int: UIView] = [:]
  private var isPerformingLoopCorrection = false
  private var isProgrammaticScroll = false
  private var currentChangeReason: FKCarouselPageChangeReason = .reload
  private var pendingCollectionReload = false
  nonisolated(unsafe) private var appObservers: [NSObjectProtocol] = []
  private var collectionHeightConstraint: NSLayoutConstraint?
  private var collectionBottomConstraint: NSLayoutConstraint?
  private var collectionTopConstraint: NSLayoutConstraint?
  private var collectionTopToIndicatorConstraint: NSLayoutConstraint?
  private var indicatorTopConstraint: NSLayoutConstraint?
  private var indicatorBottomConstraint: NSLayoutConstraint?
  private var indicatorLeadingConstraint: NSLayoutConstraint?
  private var indicatorTrailingConstraint: NSLayoutConstraint?
  private var indicatorHeightConstraint: NSLayoutConstraint?
  private var pageChangeHapticGenerator: UIImpactFeedbackGenerator?

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
    super.init(coder: coder)
    commonInit()
  }

  public convenience init(
    configuration: FKCarouselConfiguration = FKCarouselDefaults.configuration,
    items: [FKCarouselItem] = []
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    setItems(items, animated: false)
  }

  deinit {
    autoScrollController.invalidateTimer()
    appObservers.forEach(NotificationCenter.default.removeObserver)
  }

  // MARK: - Public API

  /// Applies configuration while preserving the current page when possible.
  public func apply(configuration: FKCarouselConfiguration) {
    self.configuration = configuration
  }

  /// Replaces all items and resets or preserves the current index by ID match.
  public func setItems(_ newItems: [FKCarouselItem], animated: Bool = false, preservingIndex: Bool = true) {
    let previousID = items[safe: currentPageIndex]?.id
    items = newItems
    hostedViews.removeAll()

    if preservingIndex, let previousID, let matched = newItems.firstIndex(where: { $0.id == previousID }) {
      currentPageIndex = matched
    } else {
      currentPageIndex = 0
    }

    currentChangeReason = .reload
    reloadData(animated: animated)
    updateEmptyState()
    updateAutoScrollPolicyForPageCount()
  }

  /// Scrolls to a logical page index.
  public func scrollToPage(_ index: Int, animated: Bool, reason: FKCarouselPageChangeReason = .programmatic) {
    guard pageCount > 0 else { return }
    let clamped = min(max(0, index), pageCount - 1)
    currentChangeReason = reason
    isProgrammaticScroll = true
    stateSnapshot.phase = reason == .autoScroll ? .autoAdvancing : .programmatic

    let physical = loopAdapter.physicalIndex(forLogical: clamped)
    let offset = FKCarouselLayoutEngine.contentOffset(forPhysicalIndex: physical, metrics: metrics)
    collectionView.setContentOffset(offset, animated: animated)

    if !animated {
      settle(atPhysicalIndex: physical, reason: reason)
      isProgrammaticScroll = false
    }
  }

  // MARK: - Layout

  public override var intrinsicContentSize: CGSize {
    let width = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
    let height = resolvedTotalHeight(forWidth: width)
    return CGSize(width: UIView.noIntrinsicMetric, height: height)
  }

  public override func systemLayoutSizeFitting(
    _ targetSize: CGSize,
    withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority,
    verticalFittingPriority: UILayoutPriority
  ) -> CGSize {
    let width = targetSize.width > 0 ? targetSize.width : UIScreen.main.bounds.width
    let height = resolvedTotalHeight(forWidth: width)
    return CGSize(width: targetSize.width, height: height)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    relayoutCollection()
    layoutIndicator()
    flushPendingCollectionReloadIfNeeded()
    updateVisibilityState()
  }

  public override var isHidden: Bool {
    didSet {
      guard isHidden != oldValue else { return }
      updateVisibilityState()
    }
  }

  public override func didMoveToWindow() {
    super.didMoveToWindow()
    updateVisibilityState()
    refreshAutoScroll()
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    indicatorView?.configuration = configuration.indicator
    indicatorView?.animatesIndicatorDots = configuration.motion.animatesIndicatorDots
    refreshAutoScroll()
    updateAccessibility()
  }

  public override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
    guard configuration.accessibility.supportsAccessibilityScroll, pageCount > 1 else { return false }
    switch direction {
    case .left:
      scrollToPage(currentPageIndex + 1, animated: true, reason: .userSwipe)
      return true
    case .right:
      scrollToPage(currentPageIndex - 1, animated: true, reason: .userSwipe)
      return true
    default:
      return false
    }
  }

  // MARK: - Private setup

  private func commonInit() {
    backgroundColor = .clear
    clipsToBounds = true

    collectionView.backgroundColor = .clear
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.decelerationRate = configuration.paging.decelerationRate
    collectionView.isScrollEnabled = configuration.paging.isScrollEnabled
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(FKCarouselHostCell.self, forCellWithReuseIdentifier: FKCarouselHostCell.reuseIdentifier)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(collectionView)

    collectionTopConstraint = collectionView.topAnchor.constraint(equalTo: topAnchor)
    collectionBottomConstraint = collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
    collectionHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 0)

    NSLayoutConstraint.activate([
      collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
      collectionTopConstraint!,
      collectionBottomConstraint!,
    ])

    autoScrollController.onAdvance = { [weak self] from, to in
      guard let self else { return false }
      let allowed = self.delegate?.carousel(self, willAutoAdvanceFrom: from, to: to)
        ?? self.callbacks.onWillAutoAdvance?(from, to)
        ?? true
      guard allowed else { return false }
      self.scrollToPage(to, animated: true, reason: .autoScroll)
      return true
    }

    installAppLifecycleObservers()
    installInteractionTracking()
    applyConfigurationChanges()
  }

  private func installInteractionTracking() {
    collectionView.panGestureRecognizer.addTarget(self, action: #selector(handlePanGestureState(_:)))

    let touchTracker = UILongPressGestureRecognizer(target: self, action: #selector(handleTouchTracker(_:)))
    touchTracker.minimumPressDuration = 0
    touchTracker.cancelsTouchesInView = false
    touchTracker.delegate = CarouselTouchTrackerDelegate.shared
    collectionView.addGestureRecognizer(touchTracker)
  }

  @objc private func handlePanGestureState(_ recognizer: UIPanGestureRecognizer) {
    guard configuration.autoScroll.pausesOnUserInteraction else { return }
    switch recognizer.state {
    case .began, .changed:
      autoScrollController.isUserInteracting = true
    case .ended, .cancelled, .failed:
      autoScrollController.isUserInteracting = false
    default:
      break
    }
    refreshAutoScroll()
  }

  @objc private func handleTouchTracker(_ recognizer: UILongPressGestureRecognizer) {
    guard configuration.autoScroll.pausesOnUserInteraction else { return }
    switch recognizer.state {
    case .began:
      autoScrollController.isUserInteracting = true
    case .ended, .cancelled, .failed:
      autoScrollController.isUserInteracting = false
    default:
      break
    }
    refreshAutoScroll()
  }

  private func installAppLifecycleObservers() {
    let center = NotificationCenter.default
    appObservers = [
      center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated {
          self?.autoScrollController.isAppActive = false
          self?.refreshAutoScroll()
        }
      },
      center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
        MainActor.assumeIsolated {
          self?.autoScrollController.isAppActive = true
          self?.refreshAutoScroll()
        }
      },
    ]
  }

  private func applyConfigurationChanges() {
    clipsToBounds = configuration.layout.clipsToBounds
    collectionView.decelerationRate = configuration.paging.decelerationRate
    collectionView.isScrollEnabled = configuration.paging.isScrollEnabled
    indicatorView?.configuration = configuration.indicator
    indicatorView?.animatesIndicatorDots = configuration.motion.animatesIndicatorDots
    autoScrollController.configuration = configuration.autoScroll
    gestureCoordinator.refresh(
      policy: configuration.interaction.nestedScrollPolicy,
      requiresNavigationPopGestureToFail: configuration.interaction.requiresNavigationPopGestureToFail,
      in: self,
      panGesture: collectionView.panGestureRecognizer
    )
    relayoutCollection()
    layoutIndicator()
    updateEmptyState()
    updateAutoScrollPolicyForPageCount()
    updateAccessibility()
    refreshAutoScroll()
    syncPageChangeHapticGenerator()
  }

  private func syncPageChangeHapticGenerator() {
    if configuration.motion.playsPageChangeHaptic {
      if pageChangeHapticGenerator == nil {
        pageChangeHapticGenerator = UIImpactFeedbackGenerator(style: .light)
      }
      pageChangeHapticGenerator?.prepare()
    } else {
      pageChangeHapticGenerator = nil
    }
  }

  private func playPageChangeHapticIfNeeded(from previousIndex: Int, to index: Int, reason: FKCarouselPageChangeReason) {
    guard previousIndex != index || reason == .reload else { return }
    guard configuration.motion.playsPageChangeHaptic else { return }
    guard reason == .userSwipe || reason == .autoScroll else { return }
    guard !UIAccessibility.isReduceMotionEnabled else { return }
    pageChangeHapticGenerator?.impactOccurred()
    pageChangeHapticGenerator?.prepare()
  }

  private var needsIndicatorView: Bool {
    guard pageCount > 0 || configuration.indicator.showsIndicatorForSinglePage else { return false }
    guard configuration.indicator.style != .none else { return false }
    if pageCount <= 1 {
      return !configuration.indicator.hidesForSinglePage || configuration.indicator.showsIndicatorForSinglePage
    }
    return true
  }

  private func syncIndicatorViewPresence() {
    if needsIndicatorView {
      installIndicatorViewIfNeeded()
    } else {
      removeIndicatorViewIfNeeded()
    }
  }

  private func installIndicatorViewIfNeeded() {
    guard indicatorView == nil else { return }

    let view = FKCarouselPageIndicatorView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.configuration = configuration.indicator
    view.animatesIndicatorDots = configuration.motion.animatesIndicatorDots
    view.customRenderer = customIndicatorRenderer
    addSubview(view)

    indicatorLeadingConstraint = view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16)
    indicatorTrailingConstraint = view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16)
    indicatorHeightConstraint = view.heightAnchor.constraint(equalToConstant: 24)
    indicatorLeadingConstraint?.priority = .defaultHigh
    indicatorTrailingConstraint?.priority = .defaultHigh

    NSLayoutConstraint.activate([
      indicatorLeadingConstraint!,
      indicatorTrailingConstraint!,
      indicatorHeightConstraint!,
    ])

    indicatorView = view
    syncIndicatorContent()
  }

  private func removeIndicatorViewIfNeeded() {
    guard indicatorView != nil else { return }

    indicatorTopConstraint?.isActive = false
    indicatorBottomConstraint?.isActive = false
    indicatorTopConstraint = nil
    indicatorBottomConstraint = nil
    collectionTopToIndicatorConstraint?.isActive = false

    indicatorLeadingConstraint = nil
    indicatorTrailingConstraint = nil
    indicatorHeightConstraint = nil

    indicatorView?.removeFromSuperview()
    indicatorView = nil
  }

  private func syncIndicatorContent() {
    guard let indicatorView else { return }
    indicatorView.pageCount = pageCount
    indicatorView.currentPage = currentPageIndex
    indicatorView.scrollFromLogicalPage = currentPageIndex
    indicatorView.scrollToLogicalPage = currentPageIndex
    indicatorView.scrollProgress = scrollProgress
    indicatorView.applyVisibility(pageCount: pageCount)
  }

  private func reloadData(animated: Bool) {
    loopAdapter = FKCarouselInfiniteLoopAdapter(
      isEnabled: configuration.layout.isInfiniteLoopEnabled,
      logicalCount: pageCount
    )

    syncIndicatorViewPresence()
    scrollProgress = 0
    syncIndicatorContent()

    guard hasValidLayoutMetrics else {
      pendingCollectionReload = true
      updateStateSnapshot(phase: .idle)
      return
    }

    pendingCollectionReload = false
    collectionView.reloadData()
    collectionView.layoutIfNeeded()

    let physical = loopAdapter.initialPhysicalIndex(forLogical: currentPageIndex)
    let offset = FKCarouselLayoutEngine.contentOffset(forPhysicalIndex: physical, metrics: metrics)
    collectionView.setContentOffset(offset, animated: animated)

    updateStateSnapshot(phase: .idle)
    announcePageIfNeeded()
  }

  private var hasValidLayoutMetrics: Bool {
    bounds.width > 0 && metrics.pageWidth > 0 && metrics.pageHeight > 0
  }

  private func flushPendingCollectionReloadIfNeeded() {
    guard pendingCollectionReload, hasValidLayoutMetrics else { return }
    pendingCollectionReload = false
    collectionView.reloadData()
    collectionView.layoutIfNeeded()

    let physical = loopAdapter.initialPhysicalIndex(forLogical: currentPageIndex)
    let offset = FKCarouselLayoutEngine.contentOffset(forPhysicalIndex: physical, metrics: metrics)
    collectionView.setContentOffset(offset, animated: false)
    announcePageIfNeeded()
  }

  private func relayoutCollection() {
    guard bounds.width > 0 else { return }

    metrics = FKCarouselLayoutEngine.metrics(
      bounds: bounds,
      configuration: configuration,
      safeAreaInsets: safeAreaInsets,
      intrinsicPageHeightResolver: intrinsicPageHeightResolver
    )

    guard metrics.pageWidth > 0, metrics.pageHeight > 0 else { return }

    flowLayout.pageWidth = metrics.pageWidth
    flowLayout.pageHeight = metrics.pageHeight
    flowLayout.itemSize = metrics.itemSize
    flowLayout.sectionInset = metrics.sectionInset
    flowLayout.minimumLineSpacing = configuration.layout.interPageSpacing
    flowLayout.invalidateLayout()

    collectionView.isPagingEnabled = metrics.usesPagingEnabled
    collectionView.contentInset = .zero
    invalidateIntrinsicContentSize()
  }

  private func layoutIndicator() {
    syncIndicatorViewPresence()
    layoutCollectionVerticalConstraints()

    guard let indicatorView else { return }

    let safeBottomInset = configuration.layout.respectsSafeAreaForIndicator ? safeAreaInsets.bottom : 0

    switch configuration.indicator.placement {
    case let .overlayBottom(inset):
      activateIndicatorBottom(
        equalTo: bottomAnchor,
        constant: -(inset + safeBottomInset)
      )

    case let .overlayTop(inset):
      activateIndicatorTop(equalTo: topAnchor, constant: inset)

    case let .below(spacing):
      activateIndicatorTop(equalTo: collectionView.bottomAnchor, constant: spacing)
      activateIndicatorBottom(equalTo: bottomAnchor, constant: 0)

    case let .above(spacing):
      activateIndicatorTop(equalTo: topAnchor, constant: 0)
      activateIndicatorBottom(equalTo: topAnchor, constant: 24)
      activateCollectionTopToIndicator(spacing: spacing)
    }

    indicatorView.applyVisibility(pageCount: pageCount)
  }

  private func layoutCollectionVerticalConstraints() {
    indicatorTopConstraint?.isActive = false
    indicatorBottomConstraint?.isActive = false
    collectionTopToIndicatorConstraint?.isActive = false
    collectionHeightConstraint?.isActive = false

    switch configuration.indicator.placement {
    case .overlayBottom, .overlayTop:
      // Fill the carousel vertically; avoid a competing height constraint that clips page cells.
      collectionTopConstraint?.isActive = true
      collectionBottomConstraint?.isActive = true

    case .below:
      collectionTopConstraint?.isActive = true
      collectionBottomConstraint?.isActive = false
      collectionHeightConstraint?.constant = metrics.collectionHeight
      collectionHeightConstraint?.isActive = true

    case .above:
      collectionTopConstraint?.isActive = false
      collectionBottomConstraint?.isActive = false
      collectionHeightConstraint?.constant = metrics.collectionHeight
      collectionHeightConstraint?.isActive = true
      if indicatorView == nil {
        collectionTopConstraint?.isActive = true
      }
    }
  }

  private func activateIndicatorTop(equalTo anchor: NSLayoutYAxisAnchor, constant: CGFloat) {
    guard let indicatorView else { return }
    if let constraint = indicatorTopConstraint,
       constraint.firstAnchor === indicatorView.topAnchor,
       constraint.secondAnchor === anchor {
      constraint.constant = constant
    } else {
      indicatorTopConstraint?.isActive = false
      indicatorTopConstraint = indicatorView.topAnchor.constraint(equalTo: anchor, constant: constant)
    }
    indicatorTopConstraint?.isActive = true
  }

  private func activateIndicatorBottom(equalTo anchor: NSLayoutYAxisAnchor, constant: CGFloat) {
    guard let indicatorView else { return }
    if let constraint = indicatorBottomConstraint,
       constraint.firstAnchor === indicatorView.bottomAnchor,
       constraint.secondAnchor === anchor {
      constraint.constant = constant
    } else {
      indicatorBottomConstraint?.isActive = false
      indicatorBottomConstraint = indicatorView.bottomAnchor.constraint(equalTo: anchor, constant: constant)
    }
    indicatorBottomConstraint?.isActive = true
  }

  private func activateCollectionTopToIndicator(spacing: CGFloat) {
    guard let indicatorView else { return }
    if collectionTopToIndicatorConstraint == nil {
      collectionTopToIndicatorConstraint = collectionView.topAnchor.constraint(
        equalTo: indicatorView.bottomAnchor,
        constant: spacing
      )
    } else {
      collectionTopToIndicatorConstraint?.constant = spacing
    }
    collectionTopToIndicatorConstraint?.isActive = true
  }

  private func resolvedTotalHeight(forWidth width: CGFloat) -> CGFloat {
    let bounds = CGRect(x: 0, y: 0, width: width, height: 0)
    let localMetrics = FKCarouselLayoutEngine.metrics(
      bounds: bounds,
      configuration: configuration,
      safeAreaInsets: safeAreaInsets,
      intrinsicPageHeightResolver: intrinsicPageHeightResolver
    )
    let indicatorHeight: CGFloat
    switch configuration.indicator.placement {
    case .below, .above:
      indicatorHeight = 24 + localMetrics.indicatorSpacing
    case .overlayBottom, .overlayTop:
      indicatorHeight = 0
    }
    return localMetrics.collectionHeight + indicatorHeight
  }

  private func updateEmptyState() {
    switch configuration.emptyState {
    case .collapse:
      fk_hideEmptyState(animated: true)
      isHidden = items.isEmpty
    case let .showEmptyState(scenario):
      isHidden = false
      if items.isEmpty {
        fk_applyEmptyState(.scenario(scenario), animated: true)
      } else {
        fk_hideEmptyState(animated: true)
      }
    }
  }

  private func updateAutoScrollPolicyForPageCount() {
    if pageCount <= 1 {
      autoScrollController.invalidateTimer()
    }
    autoScrollController.pageCount = pageCount
    autoScrollController.currentPageIndex = currentPageIndex
    refreshAutoScroll()
  }

  private func refreshAutoScroll() {
    autoScrollController.pageCount = pageCount
    autoScrollController.currentPageIndex = currentPageIndex
    autoScrollController.refreshTimerState()
  }

  private func updateVisibilityState() {
    let visible = window != nil && !isHidden && alpha > 0.01
    autoScrollController.isVisible = visible
    refreshAutoScroll()
  }

  private func settle(atPhysicalIndex physicalIndex: Int, reason: FKCarouselPageChangeReason) {
    if let correction = loopAdapter.loopCorrection(physicalIndex: physicalIndex) {
      isPerformingLoopCorrection = true
      let offset = FKCarouselLayoutEngine.contentOffset(forPhysicalIndex: correction.targetPhysicalIndex, metrics: metrics)
      collectionView.setContentOffset(offset, animated: false)
      isPerformingLoopCorrection = false
      reasonSettled(loopAdapter.logicalIndex(forPhysical: correction.targetPhysicalIndex), reason: correction.reason)
      return
    }

    let logical = loopAdapter.logicalIndex(forPhysical: physicalIndex)
    reasonSettled(logical, reason: reason)
  }

  private func reasonSettled(_ index: Int, reason: FKCarouselPageChangeReason) {
    guard currentPageIndex != index || reason == .reload else {
      updateStateSnapshot(phase: .idle)
      return
    }

    let previousIndex = currentPageIndex
    currentPageIndex = index
    indicatorView?.currentPage = index
    indicatorView?.scrollFromLogicalPage = index
    indicatorView?.scrollToLogicalPage = index
    indicatorView?.scrollProgress = 0
    autoScrollController.currentPageIndex = index
    updateStateSnapshot(phase: .idle)
    updateAccessibility()
    announcePageIfNeeded()

    delegate?.carousel(self, didScrollToPage: index, reason: reason)
    callbacks.onPageChanged?(index, reason)
    playPageChangeHapticIfNeeded(from: previousIndex, to: index, reason: reason)

    if reason == .userSwipe {
      autoScrollController.resetIntervalAfterManualChange()
    }

    refreshAutoScroll()
  }

  private func updateStateSnapshot(phase: FKCarouselPhase) {
    stateSnapshot = FKCarouselStateSnapshot(
      phase: phase,
      currentPageIndex: currentPageIndex,
      pageCount: pageCount,
      scrollProgress: scrollProgress
    )
  }

  private func updateAccessibility() {
    guard pageCount > 0 else {
      accessibilityLabel = nil
      return
    }

    let itemLabel = items[safe: currentPageIndex]?.accessibilityLabel
      ?? FKUIKitI18n.string("fkuikit.carousel.accessibility.slide")
    let position = FKUIKitI18n.format(
      "fkuikit.carousel.accessibility.position",
      currentPageIndex + 1,
      pageCount
    )
    accessibilityLabel = [itemLabel, position].joined(separator: ", ")
    accessibilityTraits = configuration.paging.isScrollEnabled ? [.allowsDirectInteraction] : []
  }

  private func announcePageIfNeeded() {
    guard configuration.accessibility.announcesPageChanges, pageCount > 0 else { return }
    UIAccessibility.post(notification: .pageScrolled, argument: accessibilityLabel)
  }

  private func pageView(forLogicalIndex index: Int, bounds: CGRect, reusing: UIView?) -> UIView {
    if let pageProvider, let item = items[safe: index] {
      return pageProvider(item, bounds)
    }

    if let dataSource {
      return dataSource.carousel(self, viewForPageAt: index, reusing: reusing)
    }

    let placeholder = reusing ?? UIView()
    placeholder.backgroundColor = .secondarySystemFill
    return placeholder
  }

  private func handlePageSelection(at index: Int) {
    guard let item = items[safe: index], item.isInteractive else { return }
    delegate?.carousel(self, didSelectPageAt: index)
    callbacks.onPageSelected?(index)
  }
}

// MARK: - UICollectionViewDataSource

extension FKCarousel: UICollectionViewDataSource {
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    loopAdapter.physicalCount
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let logical = loopAdapter.logicalIndex(forPhysical: indexPath.item)
    if let customCellProvider {
      return customCellProvider(collectionView, indexPath, logical)
    }

    let cell = collectionView.dequeueReusableCell(
      withReuseIdentifier: FKCarouselHostCell.reuseIdentifier,
      for: indexPath
    ) as! FKCarouselHostCell

    let reusing = hostedViews[logical]
    let page = pageView(
      forLogicalIndex: logical,
      bounds: CGRect(origin: .zero, size: metrics.itemSize),
      reusing: reusing
    )
    hostedViews[logical] = page
    page.alpha = items[safe: logical]?.isInteractive == false
      ? configuration.interaction.nonInteractiveAlpha
      : 1
    cell.attach(page)

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleCellTap(_:)))
    tap.cancelsTouchesInView = false
    page.gestureRecognizers?.forEach { page.removeGestureRecognizer($0) }
    page.addGestureRecognizer(tap)
    page.tag = logical

    return cell
  }

  @objc private func handleCellTap(_ recognizer: UITapGestureRecognizer) {
    guard let view = recognizer.view else { return }
    handlePageSelection(at: view.tag)
  }
}

// MARK: - UICollectionViewDelegate

extension FKCarousel: UICollectionViewDelegate {
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    autoScrollController.isUserInteracting = true
    refreshAutoScroll()
    stateSnapshot.phase = .dragging
    currentChangeReason = .userSwipe
  }

  public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    autoScrollController.isUserInteracting = false
    delegate?.carouselDidEndDragging(self, willDecelerate: decelerate)
    callbacks.onDidEndDragging?(decelerate)
    if !decelerate {
      handleScrollEnd()
    }
  }

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    handleScrollEnd()
  }

  public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    isProgrammaticScroll = false
    handleScrollEnd()
  }

  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard metrics.pageSpan > 0 else { return }

    let progressInfo = FKCarouselLayoutEngine.scrollProgress(
      forContentOffset: scrollView.contentOffset,
      metrics: metrics,
      pageCount: loopAdapter.physicalCount,
      clampToPageBounds: !loopAdapter.isActive
    )
    let fromLogical = loopAdapter.logicalIndex(forPhysical: progressInfo.fromPage)
    let toLogical = loopAdapter.logicalIndex(forPhysical: progressInfo.toPage)
    scrollProgress = progressInfo.progress
    indicatorView?.scrollFromLogicalPage = fromLogical
    indicatorView?.scrollToLogicalPage = toLogical
    indicatorView?.scrollProgress = progressInfo.progress

    if configuration.paging.reportsScrollProgress {
      delegate?.carousel(self, didUpdateScrollProgress: progressInfo.progress, fromPage: fromLogical, toPage: toLogical)
      callbacks.onScrollProgress?(progressInfo.progress, fromLogical, toLogical)
    }

    updateStateSnapshot(phase: stateSnapshot.phase == .idle ? .dragging : stateSnapshot.phase)
  }

  private func handleScrollEnd() {
    let physical = FKCarouselLayoutEngine.physicalIndex(
      forContentOffset: collectionView.contentOffset,
      metrics: metrics,
      pageCount: loopAdapter.physicalCount
    )
    let reason = isPerformingLoopCorrection ? .loopCorrection : currentChangeReason
    settle(atPhysicalIndex: physical, reason: reason)
    currentChangeReason = .userSwipe
  }
}

private final class CarouselTouchTrackerDelegate: NSObject, UIGestureRecognizerDelegate {
  static let shared = CarouselTouchTrackerDelegate()

  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    true
  }
}
