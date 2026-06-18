import UIKit

extension FKMediaGalleryViewController: UIGestureRecognizerDelegate {
  func installGalleryGestures() {
    let pan = UIPanGestureRecognizer(target: self, action: #selector(handleGalleryPan(_:)))
    pan.delegate = self
    view.addGestureRecognizer(pan)
    galleryPanRecognizer = pan

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleGallerySingleTap))
    tap.delegate = self
    view.addGestureRecognizer(tap)
    gallerySingleTapRecognizer = tap

    let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleGalleryLongPress(_:)))
    longPress.delegate = self
    view.addGestureRecognizer(longPress)
    galleryLongPressRecognizer = longPress
  }

  @objc fileprivate func handleGallerySingleTap() {
    switch configuration.interaction.singleTapBehavior {
    case .toggleChrome, .toggleChromeAndVideoControls:
      toggleChrome()
    case .none:
      break
    }
  }

  @objc fileprivate func handleGalleryLongPress(_ recognizer: UILongPressGestureRecognizer) {
    guard configuration.contextMenu.isEnabled, recognizer.state == .began else { return }
    presentContextMenu(from: recognizer)
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
      guard isVerticalDominant, translation.y > 0 else {
        if translation.y <= 0 {
          applyDismissProgress(0)
        }
        return
      }
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

  fileprivate func finishInteractiveDismiss(shouldDismiss: Bool) {
    if shouldDismiss {
      gallery?.dismiss(animated: true)
    } else {
      UIView.animate(withDuration: 0.2) {
        self.applyDismissProgress(0)
      }
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
      guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
      let velocity = pan.velocity(in: view)
      let translation = pan.translation(in: view)
      let verticalDelta = abs(velocity.y) + abs(translation.y)
      let horizontalDelta = abs(velocity.x) + abs(translation.x)
      return verticalDelta > horizontalDelta
    }
    return true
  }
}
