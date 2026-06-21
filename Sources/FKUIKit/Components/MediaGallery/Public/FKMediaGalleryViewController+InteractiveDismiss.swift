import UIKit

extension FKMediaGalleryViewController {
  func resetInteractiveDismiss(animated: Bool) {
    dismissTransformProgress = 0
    collectionView.isScrollEnabled = true
    let resetBlock = {
      self.teardownDismissFlyingView()
      self.setChromeAlpha(1)
      self.backdropView?.alpha = 1
      self.blurBackdropView?.alpha = 1
      self.view.backgroundColor = .black
    }
    if animated {
      UIView.animate(
        withDuration: 0.28,
        delay: 0,
        usingSpringWithDamping: 0.9,
        initialSpringVelocity: 0,
        options: [.beginFromCurrentState, .allowUserInteraction],
        animations: {
          self.setChromeAlpha(1)
          self.backdropView?.alpha = 1
          self.blurBackdropView?.alpha = 1
          self.view.backgroundColor = .black
        },
        completion: { _ in resetBlock() }
      )
    } else {
      resetBlock()
    }
  }

  func applyDismissProgress(_ progress: CGFloat) {
    dismissTransformProgress = progress
    let clamped = min(max(progress, 0), 1)
    collectionView.isScrollEnabled = clamped <= 0

    if clamped <= 0 {
      restoreInteractiveDismissToRestDuringGesture()
      return
    }

    if dismissFlyingView == nil {
      guard prepareDismissFlyingView() else { return }
    }

    collectionView.alpha = 0
    setChromeAlpha(max(0, 1 - clamped * 2.2))

    let endContainer = dismissEndContainer(for: clamped)
    let frame = FKMediaGalleryLayoutMath.aspectFitFrameInterpolated(
      contentSize: dismissFlyingContentSize,
      startContainer: view.bounds,
      endContainer: endContainer,
      progress: clamped
    )
    dismissFlyingView?.frame = frame
    dismissFlyingView?.layer.cornerRadius = (transitionSource?.cornerRadius ?? 0) * clamped

    let backdropAlpha = 1 - clamped * 0.9
    backdropView?.alpha = backdropAlpha
    blurBackdropView?.alpha = backdropAlpha
    view.backgroundColor = UIColor.black.withAlphaComponent(1 - clamped * 0.75)
  }

  func finishInteractiveDismiss(shouldDismiss: Bool) {
    if shouldDismiss, dismissFlyingView != nil {
      let endContainer = dismissEndContainer(for: 1)
      let endFrame = FKMediaGalleryLayoutMath.aspectFitFrameInterpolated(
        contentSize: dismissFlyingContentSize,
        startContainer: view.bounds,
        endContainer: endContainer,
        progress: 1
      )
      UIView.animate(
        withDuration: 0.26,
        delay: 0,
        usingSpringWithDamping: 0.94,
        initialSpringVelocity: 0,
        options: [.curveEaseOut, .beginFromCurrentState],
        animations: {
          self.dismissFlyingView?.frame = endFrame
          self.dismissFlyingView?.layer.cornerRadius = self.transitionSource?.cornerRadius ?? 0
          self.view.backgroundColor = .clear
          self.setChromeAlpha(0)
          self.backdropView?.alpha = 0
          self.blurBackdropView?.alpha = 0
        },
        completion: { _ in
          self.suppressNextDismissTransitionAnimation = true
          self.gallery?.dismiss(animated: false)
        }
      )
      return
    }

    if shouldDismiss {
      gallery?.dismiss(animated: true)
      return
    }

    if dismissFlyingView != nil {
      if dismissTransformProgress <= 0.001 {
        crossfadeOutFlyingViewAndRestoreCollection()
      } else {
        animateCancelInteractiveDismiss()
      }
      return
    }

    resetInteractiveDismiss(animated: true)
  }

  // MARK: - Private

  private func restoreInteractiveDismissToRestDuringGesture() {
    guard let flyingView = dismissFlyingView else {
      collectionView.alpha = 1
      setChromeAlpha(1)
      backdropView?.alpha = 1
      blurBackdropView?.alpha = 1
      view.backgroundColor = .black
      return
    }

    flyingView.frame = fullScreenDismissFrame()
    flyingView.layer.cornerRadius = 0
    flyingView.alpha = 1
    setChromeAlpha(1)
    backdropView?.alpha = 1
    blurBackdropView?.alpha = 1
    view.backgroundColor = .black
  }

  private func animateCancelInteractiveDismiss() {
    guard let flyingView = dismissFlyingView else {
      resetInteractiveDismiss(animated: false)
      return
    }

    dismissTransformProgress = 0
    collectionView.isScrollEnabled = true
    collectionView.alpha = 1

    let targetFrame = fullScreenDismissFrame()
    UIView.animate(
      withDuration: 0.34,
      delay: 0,
      usingSpringWithDamping: 0.84,
      initialSpringVelocity: 0,
      options: [.beginFromCurrentState, .allowUserInteraction],
      animations: {
        flyingView.frame = targetFrame
        flyingView.layer.cornerRadius = 0
        flyingView.alpha = 1
        self.setChromeAlpha(1)
        self.backdropView?.alpha = 1
        self.blurBackdropView?.alpha = 1
        self.view.backgroundColor = .black
      },
      completion: { _ in
        self.teardownDismissFlyingView()
      }
    )
  }

  private func crossfadeOutFlyingViewAndRestoreCollection() {
    dismissTransformProgress = 0
    collectionView.isScrollEnabled = true
    collectionView.alpha = 1
    setChromeAlpha(1)
    backdropView?.alpha = 1
    blurBackdropView?.alpha = 1
    view.backgroundColor = .black

    guard let flyingView = dismissFlyingView else { return }
    UIView.animate(
      withDuration: 0.12,
      delay: 0,
      options: [.beginFromCurrentState, .curveEaseOut],
      animations: {
        flyingView.alpha = 0
      },
      completion: { _ in
        self.teardownDismissFlyingView()
      }
    )
  }

  private func teardownDismissFlyingView() {
    dismissFlyingView?.removeFromSuperview()
    dismissFlyingView = nil
    dismissEndFrame = nil
    dismissFlyingContentSize = .zero
    collectionView.alpha = 1
  }

  private func fullScreenDismissFrame() -> CGRect {
    FKMediaGalleryLayoutMath.aspectFitFrame(
      contentSize: dismissFlyingContentSize,
      in: view.bounds
    )
  }

  private func prepareDismissFlyingView() -> Bool {
    if let page = currentPageView, let content = page.interactiveDismissVisualContent() {
      return mountDismissFlyingView(image: content.image, contentSize: content.contentSize)
    }
    return prepareFallbackDismissFlyingView()
  }

  private func prepareFallbackDismissFlyingView() -> Bool {
    if let source = transitionSource,
       let image = FKMediaGalleryDismissVisualRenderer.transitionSourceImage(from: source) {
      let contentSize = FKMediaGalleryLayoutMath.resolvedImageSize(from: image)
      guard contentSize.width > 0, contentSize.height > 0 else { return false }
      return mountDismissFlyingView(image: image, contentSize: contentSize)
    }
    guard let page = currentPageView,
          let snapshot = page.makeInteractiveDismissSnapshot(),
          let image = FKMediaGalleryDismissVisualRenderer.image(from: snapshot) else {
      return false
    }
    let contentSize = FKMediaGalleryLayoutMath.resolvedImageSize(from: image)
    guard contentSize.width > 0, contentSize.height > 0 else { return false }
    return mountDismissFlyingView(image: image, contentSize: contentSize)
  }

  @discardableResult
  private func mountDismissFlyingView(image: UIImage, contentSize: CGSize) -> Bool {
    let imageView = UIImageView(image: image)
    imageView.contentMode = .scaleAspectFit
    imageView.clipsToBounds = true
    imageView.frame = FKMediaGalleryLayoutMath.aspectFitFrame(
      contentSize: contentSize,
      in: view.bounds
    )
    view.insertSubview(imageView, belowSubview: chrome.topBar)
    dismissFlyingView = imageView
    dismissFlyingContentSize = contentSize
    dismissEndFrame = resolvedDismissTargetFrameInView()
    return true
  }

  private func dismissEndContainer(for progress: CGFloat) -> CGRect {
    if let endFrame = dismissEndFrame ?? resolvedDismissTargetFrameInView() {
      return endFrame
    }
    return fallbackDismissEndContainer(for: progress)
  }

  private func resolvedDismissTargetFrameInView() -> CGRect? {
    guard let source = transitionSource else { return nil }
    let sourceIndex = source.itemIndex ?? currentIndex
    guard currentIndex == sourceIndex else { return nil }
    guard let windowFrame = source.resolvedFrameInWindow(), let window = view.window else { return nil }
    return view.convert(windowFrame, from: window)
  }

  private func fallbackDismissEndContainer(for progress: CGFloat) -> CGRect {
    let startFrame = fullScreenDismissFrame()
    guard startFrame.width > 0, startFrame.height > 0 else {
      let scale = max(0.55, 1 - progress * 0.45)
      let size = CGSize(width: view.bounds.width * scale, height: view.bounds.height * scale)
      return CGRect(
        x: (view.bounds.width - size.width) * 0.5,
        y: view.bounds.midY - size.height * 0.5 + progress * 60,
        width: size.width,
        height: size.height
      )
    }
    let scale = max(0.55, 1 - progress * 0.45)
    let size = CGSize(width: startFrame.width * scale, height: startFrame.height * scale)
    return CGRect(
      x: startFrame.midX - size.width * 0.5,
      y: startFrame.midY - size.height * 0.5 + progress * 60,
      width: size.width,
      height: size.height
    )
  }

  private func setChromeAlpha(_ alpha: CGFloat) {
    chrome.topBar.alpha = alpha
    chrome.bottomBar.alpha = alpha
  }
}
