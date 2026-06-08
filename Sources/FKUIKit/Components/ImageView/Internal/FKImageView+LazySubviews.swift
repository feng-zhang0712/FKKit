import UIKit

extension FKImageView {
  /// Installs or returns the placeholder layer beneath ``imageView``.
  @discardableResult
  func ensurePlaceholderView() -> FKImageViewPlaceholderView {
    if let placeholderView { return placeholderView }
    let view = FKImageViewPlaceholderView()
    view.translatesAutoresizingMaskIntoConstraints = false
    contentContainer.insertSubview(view, belowSubview: imageView)
    NSLayoutConstraint.activate([
      view.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
      view.topAnchor.constraint(equalTo: contentContainer.topAnchor),
      view.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
    ])
    placeholderView = view
    return view
  }

  /// Removes the placeholder layer after success or when no placeholder is needed.
  func releasePlaceholderView() {
    placeholderView?.clearCustomContent()
    placeholderView?.removeFromSuperview()
    placeholderView = nil
  }

  /// Installs or returns the activity indicator when spinner chrome is needed.
  @discardableResult
  func ensureActivityIndicator() -> UIActivityIndicatorView {
    if let activityIndicator { return activityIndicator }
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.hidesWhenStopped = true
    indicator.translatesAutoresizingMaskIntoConstraints = false
    contentContainer.addSubview(indicator)
    NSLayoutConstraint.activate([
      indicator.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
      indicator.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
    ])
    activityIndicator = indicator
    return indicator
  }

  /// Installs or returns the linear progress bar when configured.
  @discardableResult
  func ensureProgressBar() -> FKProgressBar {
    if let progressBar { return progressBar }
    let bar = FKProgressBar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    bar.isHidden = true
    contentContainer.addSubview(bar)
    progressBarHeightConstraint = bar.heightAnchor.constraint(equalToConstant: 4)
    NSLayoutConstraint.activate([
      bar.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
      bar.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
      bar.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
      progressBarHeightConstraint!,
    ])
    progressBar = bar
    return bar
  }

  /// Installs or returns the failure overlay on first failure presentation.
  @discardableResult
  func ensureFailureView() -> FKImageViewFailureView {
    if let failureView { return failureView }
    let overlay = FKImageViewFailureView()
    overlay.translatesAutoresizingMaskIntoConstraints = false
    overlay.onRetry = { [weak self] in
      self?.retry()
    }
    addSubview(overlay)
    NSLayoutConstraint.activate([
      overlay.leadingAnchor.constraint(equalTo: leadingAnchor),
      overlay.trailingAnchor.constraint(equalTo: trailingAnchor),
      overlay.topAnchor.constraint(equalTo: topAnchor),
      overlay.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    failureView = overlay
    return overlay
  }

  /// Hides and removes transient loading chrome to keep the success-state hierarchy shallow.
  func releaseLoadingChromeViews() {
    activityIndicator?.stopAnimating()
    activityIndicator?.removeFromSuperview()
    activityIndicator = nil

    progressBar?.isIndeterminate = false
    progressBar?.removeFromSuperview()
    progressBar = nil
    progressBarHeightConstraint = nil
  }

  /// Hides and removes the failure overlay after success or when failure UI is disabled.
  func releaseFailureView() {
    failureView?.removeFromSuperview()
    failureView = nil
  }
}
