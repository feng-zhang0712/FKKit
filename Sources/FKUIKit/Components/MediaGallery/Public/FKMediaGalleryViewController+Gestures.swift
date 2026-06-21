import UIKit

extension FKMediaGalleryViewController: UIGestureRecognizerDelegate {
  func installGalleryGestures() {
    let pan = UIPanGestureRecognizer(target: self, action: #selector(handleGalleryPan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)
    galleryPanRecognizer = pan

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleGallerySingleTap))
    tap.cancelsTouchesInView = false
    tap.delegate = self
    collectionView.addGestureRecognizer(tap)
    gallerySingleTapRecognizer = tap
  }

  @objc fileprivate func handleGallerySingleTap() {
    switch configuration.interaction.singleTapBehavior {
    case .toggleChrome, .toggleChromeAndVideoControls:
      toggleChrome()
    case .none:
      break
    }
  }

  @objc fileprivate func handleGalleryPan(_ recognizer: UIPanGestureRecognizer) {
    guard configuration.dismissGesture.allowsInteractiveDismiss else { return }
    if currentPageView?.isBlockingInteractiveDismiss == true { return }
    if !configuration.dismissGesture.allowsDismissFromVideoPage,
       currentPageView is FKMediaGalleryVideoPageCell {
      return
    }
    let translation = recognizer.translation(in: view)
    let velocity = recognizer.velocity(in: view)
    let isVerticalDominant = abs(translation.y) >= abs(translation.x)
    switch recognizer.state {
    case .changed:
      guard isVerticalDominant else { return }
      let progress = max(0, translation.y / max(view.bounds.height, 1))
      applyDismissProgress(progress)
    case .ended, .cancelled:
      guard isVerticalDominant else {
        finishInteractiveDismiss(shouldDismiss: false)
        return
      }
      let progress = max(0, translation.y / max(view.bounds.height, 1))
      let shouldDismiss = progress > configuration.dismissGesture.dismissDistanceRatio
        || velocity.y > configuration.dismissGesture.dismissVelocityThreshold
      finishInteractiveDismiss(shouldDismiss: shouldDismiss)
    default:
      break
    }
  }

  public func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    let collectionPan = collectionView.panGestureRecognizer
    if gestureRecognizer === galleryPanRecognizer, otherGestureRecognizer === collectionPan {
      return true
    }
    if gestureRecognizer === collectionPan, otherGestureRecognizer === galleryPanRecognizer {
      return true
    }
    return false
  }

  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    if gestureRecognizer === galleryPanRecognizer {
      guard dismissTransformProgress <= 0 else { return true }
      guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
      let velocity = pan.velocity(in: view)
      let translation = pan.translation(in: view)
      let verticalDelta = abs(velocity.y) + abs(translation.y)
      let horizontalDelta = abs(velocity.x) + abs(translation.x)
      return verticalDelta > horizontalDelta * 1.15
    }
    return true
  }

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    guard gestureRecognizer === gallerySingleTapRecognizer else { return true }
    guard let touchedView = touch.view else { return true }
    if touchedView is UIControl {
      return false
    }
    if touchedView.isDescendant(of: chrome.topBar) || touchedView.isDescendant(of: chrome.bottomBar) {
      return false
    }
    return true
  }
}
