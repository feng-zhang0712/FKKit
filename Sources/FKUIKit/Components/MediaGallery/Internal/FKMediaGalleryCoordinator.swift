import UIKit

@MainActor
final class FKMediaGalleryCoordinator {
  enum SessionState {
    case idle
    case presenting
    case browsing
    case dismissing
  }

  private var state: SessionState = .idle
  private var retainSelf: FKMediaGalleryCoordinator?
  private weak var gallery: FKMediaGallery?
  private weak var hostViewController: FKMediaGalleryViewController?
  private weak var presentingViewController: UIViewController?
  private let transitioningDelegate = FKMediaGalleryTransitioningDelegate()

  func present(
    gallery: FKMediaGallery,
    from viewController: UIViewController,
    items: [FKMediaGalleryItem],
    startIndex: Int,
    transitionSource: FKMediaGalleryTransitionSource?,
    configuration: FKMediaGalleryConfiguration
  ) throws {
    guard state == .idle else {
      throw FKMediaGalleryError.alreadyPresenting
    }
    guard !items.isEmpty else {
      throw FKMediaGalleryError.emptyItems
    }

    self.gallery = gallery
    retainSelf = self
    state = .presenting

    let host = FKMediaGalleryViewController()
    let clampedStart = min(max(0, startIndex), items.count - 1)
    host.configureSession(
      items: items,
      startIndex: clampedStart,
      configuration: configuration,
      imageLoader: gallery.imageLoader,
      transitionSource: transitionSource
    )
    host.gallery = gallery
    host.galleryDelegate = gallery.delegate
    host.chromeProvider = gallery.chromeProvider
    host.onDismiss = { [weak self] finalIndex in
      self?.handleDismiss(finalIndex: finalIndex)
    }

    configurePresentation(host: host, configuration: configuration, transitionSource: transitionSource)
    hostViewController = host
    presentingViewController = viewController

    gallery.delegate?.mediaGallery(gallery, willPresentWith: items.count)
    viewController.present(host, animated: true) { [weak self] in
      self?.state = .browsing
    }
  }

  func dismiss(animated: Bool, completion: (() -> Void)?) {
    guard state == .browsing || state == .presenting else {
      completion?()
      return
    }
    state = .dismissing
    hostViewController?.galleryWillDismiss()
    presentingViewController?.dismiss(animated: animated) {
      completion?()
    }
  }

  var viewController: FKMediaGalleryViewController? { hostViewController }

  private func configurePresentation(
    host: FKMediaGalleryViewController,
    configuration: FKMediaGalleryConfiguration,
    transitionSource: FKMediaGalleryTransitionSource?
  ) {
    switch configuration.presentationStyle {
    case .fullScreen:
      host.modalPresentationStyle = .fullScreen
    case .overFullScreen:
      host.modalPresentationStyle = .overFullScreen
    }

    switch configuration.transition {
    case .system:
      break
    case .crossDissolve:
      host.modalTransitionStyle = .crossDissolve
    case .hero:
      transitioningDelegate.transition = configuration.transition
      transitioningDelegate.transitionSource = transitionSource
      host.transitioningDelegate = transitioningDelegate
      host.modalPresentationStyle = .overFullScreen
    }
  }

  private func handleDismiss(finalIndex: Int?) {
    guard state != .idle else { return }
    if let gallery {
      gallery.delegate?.mediaGallery(gallery, didDismissAt: finalIndex)
    }
    finishSession()
  }

  private func finishSession() {
    state = .idle
    hostViewController = nil
    presentingViewController = nil
    retainSelf = nil
  }
}
