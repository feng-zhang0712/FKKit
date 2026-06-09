import UIKit

extension FKImageView {
  func showLoadingChrome() {
    let presentation = configuration.loading.loadingPresentation
    switch presentation.progressMode {
    case .none:
      activityIndicator?.stopAnimating()
      progressBar?.isHidden = true
    case .activityIndicator:
      progressBar?.isHidden = true
      ensureActivityIndicator().startAnimating()
    case .linearProgress(let config):
      activityIndicator?.stopAnimating()
      let bar = ensureProgressBar()
      bar.isHidden = false
      if let config {
        bar.configuration = config
        progressBarHeightConstraint?.constant = config.layout.trackThickness
      }
      bar.isIndeterminate = true
      bar.setNeedsLayout()
      bar.layoutIfNeeded()
    }

    if presentation.includesSkeleton {
      contentContainer.fk_showSkeleton(
        configuration: presentation.skeletonConfiguration,
        animated: true,
        respectsSafeArea: false,
        blocksInteraction: false
      )
    } else if contentContainer.fk_isShowingSkeleton {
      contentContainer.fk_hideSkeleton(animated: true)
    }
  }

  func hideLoadingChrome() {
    activityIndicator?.stopAnimating()
    progressBar?.isHidden = true
    progressBar?.isIndeterminate = false
    if contentContainer.fk_isShowingSkeleton {
      contentContainer.fk_hideSkeleton(animated: true)
    }
    releaseLoadingChromeViews()
  }

  func updateLoadingChromeVisibility() {
    switch state {
    case .loading:
      showLoadingChrome()
    default:
      hideLoadingChrome()
    }
  }

  func applyCornerAndBorderStyles() {
    let style = configuration.appearance.cornerStyle
    let radius = resolvedCornerRadius(for: style)
    contentContainer.layer.cornerCurve = .continuous
    contentContainer.layer.cornerRadius = radius
    contentContainer.layer.maskedCorners = maskedCorners(for: style)
    contentContainer.clipsToBounds = radius > 0 || configuration.appearance.borderStyle != .none
    contentContainer.layer.fk_applyBorder(configuration.appearance.borderStyle)
  }

  func applyShadowStyle() {
    let radius = resolvedCornerRadius(for: configuration.appearance.cornerStyle)
    let path = radius > 0
      ? UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
      : UIBezierPath(rect: bounds).cgPath
    layer.fk_applyShadow(configuration.appearance.shadowStyle, path: path)
  }

  func resolvedCornerRadius(for style: FKImageViewCornerStyle) -> CGFloat {
    switch style {
    case .none:
      return 0
    case .fixed(let value):
      return max(0, value)
    case .capsule:
      return min(bounds.width, bounds.height) / 2
    case .perCorner(_, let radius):
      return max(0, radius)
    }
  }

  func maskedCorners(for style: FKImageViewCornerStyle) -> CACornerMask {
    switch style {
    case .none, .fixed, .capsule:
      return [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
    case .perCorner(let corners, _):
      var mask = CACornerMask()
      if corners.contains(.topLeft) { mask.insert(.layerMinXMinYCorner) }
      if corners.contains(.topRight) { mask.insert(.layerMaxXMinYCorner) }
      if corners.contains(.bottomLeft) { mask.insert(.layerMinXMaxYCorner) }
      if corners.contains(.bottomRight) { mask.insert(.layerMaxXMaxYCorner) }
      return mask.isEmpty
        ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        : mask
    }
  }
}
