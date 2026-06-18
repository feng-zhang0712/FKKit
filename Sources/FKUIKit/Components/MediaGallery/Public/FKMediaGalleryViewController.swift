import FKCoreKit
import UIKit

/// Full-screen host for horizontally paging image and video gallery pages.
@MainActor
public final class FKMediaGalleryViewController: UIViewController {
  public private(set) var items: [FKMediaGalleryItem] = []
  public private(set) var currentIndex: Int = 0

  public var currentItem: FKMediaGalleryItem? {
    guard items.indices.contains(currentIndex) else { return nil }
    return items[currentIndex]
  }

  weak var gallery: FKMediaGallery?
  weak var galleryDelegate: FKMediaGalleryDelegate?
  weak var chromeProvider: (any FKMediaGalleryChromeProviding)?
  var configuration = FKMediaGalleryConfiguration()
  var imageLoader: (any FKImageLoading)?
  var transitionSource: FKMediaGalleryTransitionSource?
  var onDismiss: ((Int?) -> Void)?

  let collectionView: UICollectionView
  private let layout = FKMediaGalleryCollectionViewLayout()
  let chrome = FKMediaGalleryChrome()
  var backdropView: UIView?
  var blurBackdropView: UIVisualEffectView?
  private var customOverlayViews: [Int: UIView] = [:]
  var isChromeVisible = true
  var dismissTransformProgress: CGFloat = 0

  var galleryPanRecognizer: UIPanGestureRecognizer?
  var gallerySingleTapRecognizer: UITapGestureRecognizer?
  var currentPageView: FKMediaGalleryPageView?
  private var memoryWarningSubscription: FKMediaGalleryMemoryWarningSubscription?
  private let audioSessionController = FKMediaGalleryAudioSessionController()

  var dataSource: UICollectionViewDiffableDataSource<GallerySection, String>!
  var activePrefetchRequests: [IndexPath: FKImageLoadRequest] = [:]
  var dismissFlyingView: UIView?
  var dismissEndFrame: CGRect?
  var dismissFlyingContentSize: CGSize = .zero
  var suppressNextDismissTransitionAnimation = false
  var needsInitialScroll = false
  private var pendingScrollToIndex: Int?
  var isPerformingProgrammaticScroll = false

  public init() {
    collectionView = FKMediaGalleryCollectionView(frame: .zero, collectionViewLayout: layout)
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public override func viewDidLoad() {
    super.viewDidLoad()
    configureHierarchy()
    configureCollectionView()
    configureChrome()
    installGalleryGestures()
    installContextMenuInteraction()
    installMemoryWarningObserver()
    FKMediaGalleryReachabilityMonitor.shared.startIfNeeded()
    applyBackgroundStyle()
    configureDiffableDataSource()
    applyItemSnapshot(scrollTo: currentIndex, animated: false)
    refreshChrome()
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    applyPendingInitialScrollIfNeeded()
  }

  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    applyPendingInitialScrollIfNeeded()
    audioSessionController.activate(policy: configuration.audioSession)
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isBeingDismissed || presentingViewController == nil {
      audioSessionController.deactivate()
      onDismiss?(currentIndex)
    }
  }

  public override var prefersStatusBarHidden: Bool { configuration.statusBarHidden }

  public override var preferredStatusBarStyle: UIStatusBarStyle {
    configuration.chrome.statusBarStyle ?? .lightContent
  }

  public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    configuration.supportedInterfaceOrientations
  }

  public override func viewWillTransition(
    to size: CGSize,
    with coordinator: UIViewControllerTransitionCoordinator
  ) {
    super.viewWillTransition(to: size, with: coordinator)
    let index = currentIndex
    coordinator.animate(alongsideTransition: { _ in
      self.layout.invalidateLayout()
      self.collectionView.collectionViewLayout.invalidateLayout()
    }, completion: { _ in
      self.scrollToItem(at: index, animated: false)
    })
  }

  func configureSession(
    items: [FKMediaGalleryItem],
    startIndex: Int,
    configuration: FKMediaGalleryConfiguration,
    imageLoader: (any FKImageLoading)?,
    transitionSource: FKMediaGalleryTransitionSource?
  ) {
    self.items = items
    self.configuration = configuration
    self.imageLoader = imageLoader
    self.transitionSource = transitionSource
    currentIndex = clampedIndex(startIndex, count: items.count)
    markNeedsScrollToInitialPage(at: currentIndex)
    modalPresentationCapturesStatusBarAppearance = true
    isModalInPresentation = !configuration.dismissGesture.allowsInteractiveDismiss
  }

  /// Replaces items while presented; preserves the current id when possible.
  public func updateItems(
    _ items: [FKMediaGalleryItem],
    currentIndex: Int? = nil,
    animated: Bool = false
  ) throws {
    guard !items.isEmpty else {
      if configuration.dismissWhenItemsBecomeEmpty {
        gallery?.dismiss(animated: animated)
      }
      throw FKMediaGalleryError.emptyItems
    }
    let previousID = self.items.indices.contains(self.currentIndex) ? self.items[self.currentIndex].id : nil
    self.items = items
    if let currentIndex {
      self.currentIndex = clampedIndex(currentIndex, count: items.count)
    } else if let previousID, let matched = items.firstIndex(where: { $0.id == previousID }) {
      self.currentIndex = matched
    } else {
      self.currentIndex = clampedIndex(self.currentIndex, count: items.count)
    }
    applyItemSnapshot(scrollTo: self.currentIndex, animated: animated)
    refreshChrome()
  }

  /// Scrolls to the page at `index` without changing the items array.
  public func scrollToItem(at index: Int, animated: Bool) {
    scrollToPage(at: index, animated: animated)
    refreshChrome()
  }

  /// Scrolls to the page with the given stable identifier.
  public func scrollToItem(withID id: String, animated: Bool) {
    guard let index = items.firstIndex(where: { $0.id == id }) else { return }
    scrollToItem(at: index, animated: animated)
  }

  func galleryWillDismiss() {
    for cell in collectionView.visibleCells {
      (cell as? FKMediaGalleryPageView)?.galleryWillDismiss()
    }
    audioSessionController.deactivate()
    trimImageLoaderMemoryCacheIfNeeded()
  }

  // MARK: - Private

  private func configureHierarchy() {
    view.backgroundColor = .black
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(collectionView)
    chrome.install(in: view)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func configureCollectionView() {
    if let galleryCollectionView = collectionView as? FKMediaGalleryCollectionView {
      galleryCollectionView.shouldAllowHorizontalPaging = { [weak self] in
        self?.currentPageView?.isBlockingHorizontalPaging != true
      }
    }
    collectionView.backgroundColor = .clear
    collectionView.isPagingEnabled = true
    collectionView.decelerationRate = .fast
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.delegate = self
    collectionView.register(
      FKMediaGalleryImagePageCell.self,
      forCellWithReuseIdentifier: FKMediaGalleryImagePageCell.reuseIdentifier
    )
    collectionView.register(
      FKMediaGalleryVideoPageCell.self,
      forCellWithReuseIdentifier: FKMediaGalleryVideoPageCell.reuseIdentifier
    )
    collectionView.register(
      FKMediaGalleryLivePhotoPageCell.self,
      forCellWithReuseIdentifier: FKMediaGalleryLivePhotoPageCell.reuseIdentifier
    )
    applyRTLLayoutIfNeeded()
  }

  private func configureChrome() {
    chrome.apply(configuration: configuration.chrome)
    chrome.topBar.onClose = { [weak self] in
      self?.gallery?.dismiss(animated: true)
    }
    chrome.topBar.onShare = { [weak self] in
      self?.shareCurrentItem()
    }
    chrome.topBar.onMuteToggle = { [weak self] in
      self?.toggleMute()
    }
  }

  private func applyBackgroundStyle() {
    blurBackdropView?.removeFromSuperview()
    blurBackdropView = nil
    backdropView?.removeFromSuperview()
    backdropView = nil

    switch configuration.chrome.backgroundStyle {
    case .black:
      view.backgroundColor = .black
    case .blackTranslucent:
      view.backgroundColor = .black
      let backdrop = UIView()
      backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.92)
      installBackdrop(backdrop)
      backdropView = backdrop
    case let .blur(style):
      view.backgroundColor = .black
      let blur = UIVisualEffectView(effect: UIBlurEffect(style: style))
      installBackdrop(blur)
      blurBackdropView = blur
    }
  }

  private func installBackdrop(_ backdrop: UIView) {
    backdrop.translatesAutoresizingMaskIntoConstraints = false
    view.insertSubview(backdrop, at: 0)
    NSLayoutConstraint.activate([
      backdrop.topAnchor.constraint(equalTo: view.topAnchor),
      backdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      backdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      backdrop.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
  }

  private func applyRTLLayoutIfNeeded() {
    let isRTL = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
    collectionView.semanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
  }

  private func refreshChrome() {
    guard let item = currentItem else { return }
    chrome.setMuteButtonVisible(
      configuration.chrome.showsMuteButton
        && configuration.video.showsMuteButton
        && FKMediaGalleryItemResolver.isVideo(item)
    )
    chrome.updatePageIndicator(
      currentIndex: currentIndex,
      total: items.count,
      item: item,
      style: configuration.chrome.pageIndicatorStyle
    )
    chrome.updateCaption(configuration.chrome.showsCaption ? item.caption : nil)
    let captionBottomInset: CGFloat
    if FKMediaGalleryItemResolver.isVideo(item) {
      captionBottomInset = 104
    } else {
      captionBottomInset = 16
    }
    chrome.setCaptionBottomInset(captionBottomInset)
    refreshCustomOverlay(for: currentIndex, item: item)
    UIAccessibility.post(notification: .pageScrolled, argument: chrome.topBar)
  }

  private func refreshCustomOverlay(for index: Int, item: FKMediaGalleryItem) {
    customOverlayViews.values.forEach { $0.removeFromSuperview() }
    customOverlayViews.removeAll()
    guard let overlay = chromeProvider?.mediaGallery(self, overlayForPageAt: index, item: item) else { return }
    overlay.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(overlay)
    NSLayoutConstraint.activate([
      overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      overlay.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -72),
    ])
    customOverlayViews[index] = overlay
  }

  func toggleChrome() {
    isChromeVisible.toggle()
    chrome.setChromeVisible(isChromeVisible, animated: true)
    if isChromeVisible {
      revealVideoControlsForCurrentPageIfNeeded()
    }
  }

  private func revealVideoControlsForCurrentPageIfNeeded() {
    guard
      let cell = pageView(at: currentIndex) as? FKMediaGalleryVideoPageCell
    else {
      return
    }
    switch configuration.interaction.singleTapBehavior {
    case .toggleChromeAndVideoControls:
      cell.embeddedPlayerView.revealControls(animated: true)
    case .toggleChrome, .none:
      break
    }
  }

  private func toggleMute() {
    guard let cell = pageView(at: currentIndex) as? FKMediaGalleryVideoPageCell,
          let player = cell.player else {
      return
    }
    player.isMuted.toggle()
    chrome.setMuted(player.isMuted)
  }

  func notifyCurrentPageLifecycle(previousIndex: Int) {
    if previousIndex != currentIndex {
      if let previous = pageView(at: previousIndex) {
        previous.didEndDisplaying()
      }
      if let gallery {
        galleryDelegate?.mediaGallery(gallery, didChangeCurrentIndex: currentIndex, previousIndex: previousIndex)
      }
    }
    if let current = pageView(at: currentIndex) {
      current.didBecomeCurrent(configuration: configuration)
    }
    enforceImageMemoryRetention(around: currentIndex)
    currentPageView = pageView(at: currentIndex)
    refreshChrome()
  }

  func pageView(at index: Int) -> FKMediaGalleryPageView? {
    guard items.indices.contains(index) else { return nil }
    let itemID = items[index].id
    guard let indexPath = dataSource.indexPath(for: itemID) else { return nil }
    return collectionView.cellForItem(at: indexPath) as? FKMediaGalleryPageView
  }

  private func installMemoryWarningObserver() {
    memoryWarningSubscription = FKMediaGalleryMemoryWarningSubscription { [weak self] in
      self?.handleMemoryWarning()
    }
  }

  private func handleMemoryWarning() {
    releaseImageContent(exceptIndex: currentIndex)
    trimImageLoaderMemoryCacheIfNeeded()
  }

  private func enforceImageMemoryRetention(around index: Int) {
    let radius = FKMediaGalleryImageLoadingMath.retentionRadius(
      for: configuration.memory.maxRetainedImagePages
    )
    for cell in collectionView.visibleCells {
      guard let page = cell as? FKMediaGalleryPageView else { continue }
      guard abs(page.pageIndex - index) > radius else { continue }
      page.releaseRetainedImageContent()
    }
  }

  private func releaseImageContent(exceptIndex: Int?) {
    for cell in collectionView.visibleCells {
      guard let page = cell as? FKMediaGalleryPageView else { continue }
      if let exceptIndex, page.pageIndex == exceptIndex { continue }
      page.releaseRetainedImageContent()
    }
  }

  private func trimImageLoaderMemoryCacheIfNeeded() {
    guard configuration.memory.trimsImageLoaderMemoryCacheOnMemoryPressure else { return }
    let loader = imageLoader ?? FKImageLoader.shared
    guard let fkLoader = loader as? FKImageLoader else { return }
    Task { await fkLoader.clearMemoryCache() }
  }

  func clampedIndex(_ index: Int, count: Int) -> Int {
    guard count > 0 else { return 0 }
    return min(max(0, index), count - 1)
  }

  func updateCurrentIndexFromScrollView() {
    guard !isPerformingProgrammaticScroll, !needsInitialScroll else { return }
    let width = max(collectionView.bounds.width, 1)
    let page = Int(round(collectionView.contentOffset.x / width))
    let previous = currentIndex
    currentIndex = clampedIndex(page, count: items.count)
    notifyCurrentPageLifecycle(previousIndex: previous)
  }

  func markNeedsScrollToInitialPage(at index: Int) {
    pendingScrollToIndex = clampedIndex(index, count: items.count)
    needsInitialScroll = true
    collectionView.alpha = 0
  }

  func scrollToPage(at index: Int, animated: Bool) {
    guard items.indices.contains(index) else { return }
    let targetIndex = clampedIndex(index, count: items.count)
    guard isCollectionViewReadyForPaging else {
      pendingScrollToIndex = targetIndex
      needsInitialScroll = true
      currentIndex = targetIndex
      return
    }
    let previous = currentIndex
    isPerformingProgrammaticScroll = true
    currentIndex = targetIndex
    collectionView.setContentOffset(pageContentOffset(for: targetIndex), animated: animated)
    if animated {
      return
    }
    collectionView.layoutIfNeeded()
    isPerformingProgrammaticScroll = false
    notifyCurrentPageLifecycle(previousIndex: previous)
    refreshChrome()
  }

  func applyPendingInitialScrollIfNeeded() {
    guard needsInitialScroll, let targetIndex = pendingScrollToIndex else { return }
    guard isCollectionViewReadyForPaging else { return }

    let targetOffset = pageContentOffset(for: targetIndex)
    if abs(collectionView.contentOffset.x - targetOffset.x) > 0.5 {
      let previous = currentIndex
      isPerformingProgrammaticScroll = true
      currentIndex = targetIndex
      collectionView.setContentOffset(targetOffset, animated: false)
      collectionView.layoutIfNeeded()
      isPerformingProgrammaticScroll = false
      notifyCurrentPageLifecycle(previousIndex: previous)
      refreshChrome()
    } else if currentIndex != targetIndex {
      let previous = currentIndex
      currentIndex = targetIndex
      notifyCurrentPageLifecycle(previousIndex: previous)
      refreshChrome()
    }

    guard abs(collectionView.contentOffset.x - targetOffset.x) <= 0.5 else { return }
    needsInitialScroll = false
    pendingScrollToIndex = nil
    if collectionView.alpha < 1 {
      collectionView.alpha = 1
    }
  }

  private var isCollectionViewReadyForPaging: Bool {
    guard collectionView.bounds.width > 0, !items.isEmpty else { return false }
    let requiredWidth = collectionView.bounds.width * CGFloat(items.count)
    return collectionView.contentSize.width >= requiredWidth - 1
  }

  private func pageContentOffset(for index: Int) -> CGPoint {
    CGPoint(x: CGFloat(index) * collectionView.bounds.width, y: 0)
  }

  func placeholderImage(for index: Int) -> UIImage? {
    guard index == currentIndex else { return nil }
    return transitionSource?.placeholderImage
  }
}
