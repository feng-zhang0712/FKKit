import FKCoreKit
import UIKit

extension FKMediaGalleryViewController {
  enum GallerySection: Hashable {
    case main
  }

  func configureDiffableDataSource() {
    dataSource = UICollectionViewDiffableDataSource<GallerySection, String>(
      collectionView: collectionView
    ) { [weak self] collectionView, indexPath, itemID in
      guard let self else { return UICollectionViewCell() }
      guard let item = self.item(withID: itemID) else { return UICollectionViewCell() }
      switch item.kind {
      case .image:
        let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: FKMediaGalleryImagePageCell.reuseIdentifier,
          for: indexPath
        ) as! FKMediaGalleryImagePageCell
        self.configurePageCell(cell, item: item, index: indexPath.item)
        return cell
      case .video:
        let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: FKMediaGalleryVideoPageCell.reuseIdentifier,
          for: indexPath
        ) as! FKMediaGalleryVideoPageCell
        self.configurePageCell(cell, item: item, index: indexPath.item)
        return cell
      case .livePhoto:
        let cell = collectionView.dequeueReusableCell(
          withReuseIdentifier: FKMediaGalleryLivePhotoPageCell.reuseIdentifier,
          for: indexPath
        ) as! FKMediaGalleryLivePhotoPageCell
        self.configurePageCell(cell, item: item, index: indexPath.item)
        return cell
      }
    }
    collectionView.prefetchDataSource = self
  }

  func applyItemSnapshot(scrollTo index: Int, animated: Bool) {
    markNeedsScrollToInitialPage(at: index)
    var snapshot = NSDiffableDataSourceSnapshot<GallerySection, String>()
    snapshot.appendSections([.main])
    snapshot.appendItems(items.map(\.id), toSection: .main)
    dataSource.apply(snapshot, animatingDifferences: animated) { [weak self] in
      self?.applyPendingInitialScrollIfNeeded()
    }
  }

  func item(withID id: String) -> FKMediaGalleryItem? {
    items.first { $0.id == id }
  }

  func configurePageCell(_ cell: FKMediaGalleryPageView, item: FKMediaGalleryItem, index: Int) {
    cell.pageIndex = index
    cell.prepareForDisplay(
      item: item,
      configuration: configuration,
      imageLoader: imageLoader,
      placeholder: placeholderImage(for: index)
    )
    if let imageCell = cell as? FKMediaGalleryImagePageCell {
      imageCell.onLoadFailed = { [weak self] (error: FKMediaGalleryError) in
        guard let self, let gallery = self.gallery else { return }
        self.galleryDelegate?.mediaGallery(gallery, didFailToLoad: item, at: index, error: error)
      }
    }
    if let videoCell = cell as? FKMediaGalleryVideoPageCell {
      videoCell.onLoadFailed = { [weak self] (error: FKMediaGalleryError) in
        guard let self, let gallery = self.gallery else { return }
        self.galleryDelegate?.mediaGallery(gallery, didFailToLoad: item, at: index, error: error)
      }
      videoCell.onRequestFullScreenPlayer = { [weak self] (player: FKVideoPlayer) in
        guard let self, let gallery = self.gallery else { return }
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
    if let livePhotoCell = cell as? FKMediaGalleryLivePhotoPageCell {
      livePhotoCell.onLoadFailed = { [weak self] (error: FKMediaGalleryError) in
        guard let self, let gallery = self.gallery else { return }
        self.galleryDelegate?.mediaGallery(gallery, didFailToLoad: item, at: index, error: error)
      }
    }
  }

  func imagePrefetchRequest(for index: Int) -> FKImageLoadRequest? {
    guard items.indices.contains(index) else { return nil }
    guard case let .image(source) = items[index].kind else { return nil }
    guard case let .url(url, options) = source else { return nil }
    let screenScale = FKMediaGalleryImageLoadingMath.screenScale(for: collectionView)
    let targetSize = FKMediaGalleryImageLoadingMath.decodeTargetSize(
      bounds: collectionView.bounds.size,
      screenScale: screenScale,
      maximumZoomScale: configuration.zoom.maximumZoomScale,
      isCurrentPage: false
    )
    return FKImageLoadRequest(url: url, targetSize: targetSize, cacheKey: options.cacheKey)
  }

  func shouldPrefetchItem(at index: Int) -> Bool {
    guard configuration.prefetchNeighborCount > 0 else { return false }
    return abs(index - currentIndex) <= configuration.prefetchNeighborCount
  }
}

extension FKMediaGalleryViewController: UICollectionViewDataSourcePrefetching {
  public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
    let loader = imageLoader ?? FKImageLoader.shared
    for indexPath in indexPaths {
      guard shouldPrefetchItem(at: indexPath.item) else { continue }
      guard let request = imagePrefetchRequest(for: indexPath.item) else { continue }
      activePrefetchRequests[indexPath] = request
      if let fkLoader = loader as? FKImageLoader {
        Task { await fkLoader.prefetch(request) }
      } else {
        Task { _ = try? await loader.loadImage(for: request) }
      }
    }
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    cancelPrefetchingForItemsAt indexPaths: [IndexPath]
  ) {
    let loader = imageLoader ?? FKImageLoader.shared
    for indexPath in indexPaths {
      guard let request = activePrefetchRequests.removeValue(forKey: indexPath) else { continue }
      if let fkLoader = loader as? FKImageLoader {
        fkLoader.cancelPrefetch(for: request)
      } else {
        loader.cancelLoad(for: request)
      }
    }
  }
}

extension FKMediaGalleryViewController: UICollectionViewDelegate {
  public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    if dismissTransformProgress > 0 {
      resetInteractiveDismiss(animated: false)
    }
  }

  public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    updateCurrentIndexFromScrollView()
  }

  public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    isPerformingProgrammaticScroll = false
    guard !needsInitialScroll else { return }
    updateCurrentIndexFromScrollView()
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    willDisplay cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    if indexPath.item == currentIndex, let page = cell as? FKMediaGalleryPageView {
      page.didBecomeCurrent(configuration: configuration)
    }
  }

  public func collectionView(
    _ collectionView: UICollectionView,
    didEndDisplaying cell: UICollectionViewCell,
    forItemAt indexPath: IndexPath
  ) {
    let stillVisible = collectionView.indexPathsForVisibleItems.contains { $0.item == indexPath.item }
    guard !stillVisible else { return }
    (cell as? FKMediaGalleryPageView)?.didEndDisplaying()
  }
}
