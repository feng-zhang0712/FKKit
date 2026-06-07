import UIKit

/// Internal `UICollectionView` delegate/data-source bridge so collection callbacks stay off the public `FKTabBar` API surface.
@MainActor
final class FKTabBarCollectionCoordinator: NSObject {
  weak var host: FKTabBar?
}

// MARK: - UICollectionViewDataSource

extension FKTabBarCollectionCoordinator: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    host?.visibleItems.count ?? 0
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let host else {
      return collectionView.dequeueReusableCell(withReuseIdentifier: "FKTabBarItemCell", for: indexPath)
    }
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FKTabBarItemCell", for: indexPath) as! FKTabBarItemCell
    cell.apply(
      host.modelForCell(at: indexPath.item, selectionProgress: host.progressForCell(indexPath.item)),
      customization: host.customization,
      badgeConfiguration: host.badgeConfiguration,
      badgeAnimation: host.badgeAnimation
    )
    cell.onTap = { [weak host, weak cell] button in
      guard let host else { return }
      guard let cell, let actualIndexPath = collectionView.indexPath(for: cell) else { return }
      guard let item = host.visibleItems[fk_safe: actualIndexPath.item] else { return }
      host.customization?.animateInteraction(on: button, phase: .tap, item: item)
      host.setSelectedIndex(actualIndexPath.item, animated: true, reason: .userTap)
    }
    cell.onLongPress = { [weak host, weak cell] button in
      guard let host else { return }
      guard host.isLongPressEnabled else { return }
      guard let cell, let actualIndexPath = collectionView.indexPath(for: cell) else { return }
      let index = actualIndexPath.item
      guard let item = host.visibleItems[fk_safe: index] else { return }
      guard item.isEnabled else { return }
      host.customization?.animateInteraction(on: button, phase: .longPress, item: item)
      host.onLongPress?(item, index)
      host.delegate?.tabBar(host, didLongPress: item, at: index)
    }
    return cell
  }
}

// MARK: - UICollectionViewDelegate

extension FKTabBarCollectionCoordinator: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
    host?.visibleItems[fk_safe: indexPath.item]?.isEnabled ?? false
  }
}

// MARK: - UIScrollViewDelegate

extension FKTabBarCollectionCoordinator: UIScrollViewDelegate {
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let host, scrollView === host.collectionView else { return }
    host.updateIndicatorFrame(animated: false)
    host.updateScrollEdgeFadeOpacity()
  }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FKTabBarCollectionCoordinator: UICollectionViewDelegateFlowLayout {
  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    guard let host else {
      return CGSize(width: 44, height: 44)
    }
    guard host.visibleItems.indices.contains(indexPath.item) else {
      let layout = host.resolvedLayoutForCurrentEnvironment()
      return CGSize(width: 44, height: max(FKTabBarLayoutMetrics.minimumBarHeight(for: layout), layout.minimumItemHeight))
    }
    return host.cachedItemSize(at: indexPath.item)
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumLineSpacingForSectionAt section: Int
  ) -> CGFloat {
    0
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    minimumInteritemSpacingForSectionAt section: Int
  ) -> CGFloat {
    guard let host else { return 0 }
    let layout = host.resolvedLayoutForCurrentEnvironment()
    if layout.widthMode == .fillEqually { return 0 }
    return layout.itemSpacing
  }

  func collectionView(
    _ collectionView: UICollectionView,
    layout collectionViewLayout: UICollectionViewLayout,
    insetForSectionAt section: Int
  ) -> UIEdgeInsets {
    guard let host else { return .zero }
    let layout = host.resolvedLayoutForCurrentEnvironment()
    if layout.widthMode == .fillEqually {
      return UIEdgeInsets(
        top: layout.contentInsets.top,
        left: layout.contentInsets.leading,
        bottom: layout.contentInsets.bottom,
        right: layout.contentInsets.trailing
      )
    }
    if let distribution = host.contentDistribution(for: layout, in: collectionView.bounds.width) {
      return UIEdgeInsets(
        top: layout.contentInsets.top,
        left: distribution.leadingInset,
        bottom: layout.contentInsets.bottom,
        right: distribution.trailingInset
      )
    }
    return UIEdgeInsets(
      top: layout.contentInsets.top,
      left: layout.contentInsets.leading,
      bottom: layout.contentInsets.bottom,
      right: layout.contentInsets.trailing
    )
  }
}
