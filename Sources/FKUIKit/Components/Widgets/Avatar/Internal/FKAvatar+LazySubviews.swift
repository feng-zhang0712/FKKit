import UIKit

extension FKAvatar {
  // MARK: - Image view

  /// Creates and attaches ``FKImageView`` when image or URL loading is required.
  @discardableResult
  func ensureImageView() -> FKImageView {
    if let imageView { return imageView }

    let view = FKImageView()
    view.isUserInteractionEnabled = false
    view.onStateChange = { [weak self] state in
      self?.handleImageViewStateChange(state)
    }
    contentContainer.addSubview(view)
    imageView = view
    configureImageView()
    setNeedsLayout()
    return view
  }

  /// Removes ``FKImageView`` when fallback-only presentation no longer needs it.
  func releaseImageView() {
    imageView?.onStateChange = nil
    imageView?.removeFromSuperview()
    imageView = nil
  }

  /// Attaches or detaches ``FKImageView`` for the current content mode.
  ///
  /// Scheme B: retains an existing ``FKImageView`` across ``resetForReuse()`` so URL-heavy list cells
  /// avoid recreate churn; releases only for sustained initials or placeholder fallback.
  func syncImageViewAttachment() {
    let needsImageView = presentationMode == .image
      || presentationMode == .loading
      || presentationMode == .failed
      || storedImage != nil
      || imageView?.url != nil

    if needsImageView {
      _ = ensureImageView()
    } else if presentationMode == .initials || presentationMode == .placeholder {
      releaseImageView()
    }
  }

  /// Inserts a fallback presentation subview beneath ``FKImageView`` when present.
  func insertPresentationSubview(_ view: UIView) {
    if let imageView {
      contentContainer.insertSubview(view, belowSubview: imageView)
    } else {
      contentContainer.insertSubview(view, at: 0)
    }
  }

  // MARK: - Initials

  @discardableResult
  func ensureInitialsLabel() -> UILabel {
    if let initialsLabel { return initialsLabel }

    let label = UILabel()
    label.isUserInteractionEnabled = false
    label.textAlignment = .center
    label.adjustsFontForContentSizeCategory = true
    insertPresentationSubview(label)
    initialsLabel = label
    setNeedsLayout()
    return label
  }

  func releaseInitialsLabel() {
    initialsLabel?.removeFromSuperview()
    initialsLabel = nil
  }

  // MARK: - Placeholder

  @discardableResult
  func ensurePlaceholderImageView() -> UIImageView {
    if let placeholderImageView { return placeholderImageView }
    let view = UIImageView()
    view.isUserInteractionEnabled = false
    view.contentMode = .scaleAspectFit
    view.tintColor = configuration.appearance.placeholderTintColor
    insertPresentationSubview(view)
    placeholderImageView = view
    setNeedsLayout()
    return view
  }

  func releasePlaceholderImageView() {
    placeholderImageView?.removeFromSuperview()
    placeholderImageView = nil
  }

  // MARK: - Loading skeleton

  @discardableResult
  func ensureSkeletonView() -> FKSkeletonView {
    if let skeletonView { return skeletonView }
    let view = FKSkeletonView()
    view.isUserInteractionEnabled = false
    contentContainer.addSubview(view)
    skeletonView = view
    setNeedsLayout()
    return view
  }

  func releaseSkeletonView() {
    skeletonView?.hide(animated: false)
    skeletonView?.removeFromSuperview()
    skeletonView = nil
  }

  // MARK: - Verified badge

  @discardableResult
  func ensureVerifiedBadgeView() -> UIImageView {
    if let verifiedBadgeView { return verifiedBadgeView }
    let view = UIImageView()
    view.isUserInteractionEnabled = false
    view.contentMode = .scaleAspectFit
    view.tintColor = configuration.appearance.verifiedBadgeTintColor
    addSubview(view)
    verifiedBadgeView = view
    setNeedsLayout()
    return view
  }

  func releaseVerifiedBadgeView() {
    verifiedBadgeView?.removeFromSuperview()
    verifiedBadgeView = nil
  }

  // MARK: - Presence

  @discardableResult
  func ensurePresenceIndicator() -> FKPresenceIndicator {
    if let presenceIndicator { return presenceIndicator }
    let indicator = FKPresenceIndicator()
    indicator.isEmbeddedInAvatar = true
    addSubview(indicator)
    presenceIndicator = indicator
    setNeedsLayout()
    return indicator
  }

  func releasePresenceIndicator() {
    presenceIndicator?.removeFromSuperview()
    presenceIndicator = nil
  }

  // MARK: - Presentation sync

  /// Attaches or removes optional presentation subviews for the current ``presentationMode``.
  func syncLazyPresentationSubviews() {
    switch presentationMode {
    case .initials:
      releasePlaceholderImageView()
      releaseSkeletonView()
      _ = ensureInitialsLabel()

    case .placeholder, .failed:
      releaseInitialsLabel()
      releaseSkeletonView()
      let placeholder = ensurePlaceholderImageView()
      placeholder.tintColor = configuration.appearance.placeholderTintColor
      placeholder.image = FKAvatarContentRenderer.placeholderImage(
        symbolName: configuration.appearance.placeholderSymbolName,
        diameter: configuration.layout.size.diameter
      )

    case .loading:
      releaseInitialsLabel()
      releasePlaceholderImageView()
      if configuration.appearance.prefersSkeletonLoadingIndicator {
        let skeleton = ensureSkeletonView()
        skeleton.show(animated: true)
      } else {
        releaseSkeletonView()
      }

    default:
      releaseInitialsLabel()
      releasePlaceholderImageView()
      releaseSkeletonView()
    }
  }
}
