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
  private var backdropView: UIView?
  private var blurBackdropView: UIVisualEffectView?
  private var customOverlayViews: [Int: UIView] = [:]
  private var isChromeVisible = true
  private var dismissTransformProgress: CGFloat = 0

  var galleryPanRecognizer: UIPanGestureRecognizer?
  var gallerySingleTapRecognizer: UITapGestureRecognizer?
  var galleryLongPressRecognizer: UILongPressGestureRecognizer?
  var currentPageView: FKMediaGalleryPageView?

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
    applyBackgroundStyle()
    reloadData(scrollTo: currentIndex, animated: false)
  }

  public override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    layout.invalidateLayout()
  }

  public override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if isBeingDismissed || presentingViewController == nil {
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
    reloadData(scrollTo: self.currentIndex, animated: animated)
    refreshChrome()
  }

  /// Scrolls to the page at `index` without changing the items array.
  public func scrollToItem(at index: Int, animated: Bool) {
    guard items.indices.contains(index) else { return }
    currentIndex = index
    collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
    refreshChrome()
    notifyCurrentPageLifecycle(previousIndex: index)
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
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.register(
      FKMediaGalleryImagePageCell.self,
      forCellWithReuseIdentifier: FKMediaGalleryImagePageCell.reuseIdentifier
    )
    collectionView.register(
      FKMediaGalleryVideoPageCell.self,
      forCellWithReuseIdentifier: FKMediaGalleryVideoPageCell.reuseIdentifier
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

  private func reloadData(scrollTo index: Int, animated: Bool) {
    collectionView.reloadData()
    collectionView.layoutIfNeeded()
    scrollToItem(at: index, animated: animated)
  }

  private func refreshChrome() {
    guard let item = currentItem else { return }
    chrome.setMuteButtonVisible(
      configuration.chrome.showsMuteButton && FKMediaGalleryItemResolver.isVideo(item)
    )
    chrome.updatePageIndicator(
      currentIndex: currentIndex,
      total: items.count,
      item: item,
      style: configuration.chrome.pageIndicatorStyle
    )
    chrome.updateCaption(configuration.chrome.showsCaption ? item.caption : nil)
    let captionBottomInset: CGFloat = FKMediaGalleryItemResolver.isVideo(item) ? 104 : 16
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

  func presentContextMenu(from recognizer: UILongPressGestureRecognizer) {
    guard let item = currentItem else { return }
    let actions = FKMediaGalleryContextMenuBuilder.makeActions(
      for: item,
      configuration: configuration.contextMenu,
      handlers: .init(
        onSave: { [weak self] in
          guard let self, let item = self.currentItem else { return }
          Task { await self.saveGalleryItemToPhotos(item, at: self.currentIndex) }
        },
        onShare: { [weak self] in self?.shareCurrentItem() },
        onEdit: { [weak self] in
          guard let self, let item = self.currentItem, let gallery = self.gallery else { return }
          _ = self.galleryDelegate?.mediaGallery(gallery, didRequestEdit: item, at: self.currentIndex)
        }
      )
    )
    let location = recognizer.location(in: view)
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    for action in actions {
      alert.addAction(UIAlertAction(title: action.title, style: .default) { _ in action.handler() })
    }
    alert.addAction(UIAlertAction(title: FKMediaGalleryI18n.closeTitle, style: .cancel))
    if let popover = alert.popoverPresentationController {
      popover.sourceView = view
      popover.sourceRect = CGRect(origin: location, size: .zero)
    }
    present(alert, animated: true)
  }

  func applyDismissProgress(_ progress: CGFloat) {
    dismissTransformProgress = progress
    let scale = max(0.86, 1 - progress * 0.12)
    collectionView.transform = CGAffineTransform(translationX: 0, y: progress * 120).scaledBy(x: scale, y: scale)
    let backdropAlpha = 1 - progress * 0.35
    backdropView?.alpha = backdropAlpha
    blurBackdropView?.alpha = backdropAlpha
  }

  private func notifyCurrentPageLifecycle(previousIndex: Int) {
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
    prefetchNeighborImages(around: currentIndex)
    currentPageView = pageView(at: currentIndex)
    refreshChrome()
  }

  func pageView(at index: Int) -> FKMediaGalleryPageView? {
    collectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? FKMediaGalleryPageView
  }

  func prefetchNeighborImages(around index: Int) {
    guard configuration.prefetchNeighborCount > 0 else { return }
    let loader = imageLoader ?? FKImageLoader.shared
    let radius = configuration.prefetchNeighborCount
    let indices = (-radius...radius)
      .map { index + $0 }
      .filter { $0 >= 0 && $0 < items.count && $0 != index }
    for neighbor in indices {
      guard case let .image(source) = items[neighbor].kind else { continue }
      guard case let .url(url, options) = source else { continue }
      let request = FKImageLoadRequest(url: url, cacheKey: options.cacheKey)
      Task { @MainActor in
        _ = try? await loader.loadImage(for: request)
      }
    }
  }

  private func clampedIndex(_ index: Int, count: Int) -> Int {
    guard count > 0 else { return 0 }
    return min(max(0, index), count - 1)
  }

  private func placeholderImage(for index: Int) -> UIImage? {
    guard index == currentIndex else { return nil }
    return transitionSource?.placeholderImage
  }
}

extension FKMediaGalleryViewController: UICollectionViewDataSource {
  public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    items.count
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    let item = items[indexPath.item]
    switch item.kind {
    case .image:
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: FKMediaGalleryImagePageCell.reuseIdentifier,
        for: indexPath
      ) as! FKMediaGalleryImagePageCell
      configurePageCell(cell, item: item, index: indexPath.item)
      return cell
    case .video:
      let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: FKMediaGalleryVideoPageCell.reuseIdentifier,
        for: indexPath
      ) as! FKMediaGalleryVideoPageCell
      configurePageCell(cell, item: item, index: indexPath.item)
      return cell
    }
  }

  private func configurePageCell(_ cell: FKMediaGalleryPageView, item: FKMediaGalleryItem, index: Int) {
    cell.pageIndex = index
    cell.prepareForDisplay(
      item: item,
      configuration: configuration,
      imageLoader: imageLoader,
      placeholder: placeholderImage(for: index)
    )
    if let imageCell = cell as? FKMediaGalleryImagePageCell {
      imageCell.onLoadFailed = { [weak self] (error: FKMediaGalleryError) in
        guard let self, let gallery = self.gallery, let item = self.currentItem else { return }
        self.galleryDelegate?.mediaGallery(gallery, didFailToLoad: item, at: index, error: error)
      }
    }
    if let videoCell = cell as? FKMediaGalleryVideoPageCell {
      videoCell.onLoadFailed = { [weak self] (error: FKMediaGalleryError) in
        guard let self, let gallery = self.gallery, let item = self.currentItem else { return }
        self.galleryDelegate?.mediaGallery(gallery, didFailToLoad: item, at: index, error: error)
      }
      videoCell.onRequestFullScreenPlayer = { [weak self] (player: FKVideoPlayer) in
        guard let self, let gallery = self.gallery, let item = self.currentItem else { return }
        if self.galleryDelegate?.mediaGallery(
          gallery,
          requestFullScreenVideoPlayerFor: item,
          at: index,
          player: player
        ) == true {
          return
        }
        let controller = FKVideoPlayerViewController(player: player, embeddedView: videoCell.embeddedPlayerView)
        self.present(controller, animated: true)
      }
    }
  }
}

extension FKMediaGalleryViewController: UICollectionViewDelegate {
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    if dismissTransformProgress > 0 {
      applyDismissProgress(0)
    }
  }

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    updateCurrentIndexFromScrollView()
  }

  public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    updateCurrentIndexFromScrollView()
  }

  private func updateCurrentIndexFromScrollView() {
    let width = max(collectionView.bounds.width, 1)
    let page = Int(round(collectionView.contentOffset.x / width))
    let previous = currentIndex
    currentIndex = clampedIndex(page, count: items.count)
    notifyCurrentPageLifecycle(previousIndex: previous)
  }

  public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    if indexPath.item == currentIndex, let page = cell as? FKMediaGalleryPageView {
      page.didBecomeCurrent(configuration: configuration)
    }
  }

  public func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    let stillVisible = collectionView.indexPathsForVisibleItems.contains { $0.item == indexPath.item }
    guard !stillVisible else { return }
    (cell as? FKMediaGalleryPageView)?.didEndDisplaying()
  }
}
