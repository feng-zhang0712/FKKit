import UIKit

/// Top chrome bar: close, optional share/mute, page indicator.
@MainActor
final class FKMediaGalleryTopChromeView: UIView {
  var onClose: (() -> Void)?
  var onShare: (() -> Void)?
  var onMuteToggle: (() -> Void)?

  private let closeButton = UIButton(type: .system)
  private let topTrailingStack = UIStackView()
  private var pageLabel: UILabel?
  private var dotsStack: UIStackView?
  private var shareButton: UIButton?
  private var muteButton: UIButton?
  private var dotViews: [UIView] = []
  private var isMuted = false

  /// Anchor for share-sheet popover presentation.
  var shareAnchorView: UIView { shareButton ?? closeButton }

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = true

    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.tintColor = .white
    closeButton.accessibilityLabel = FKMediaGalleryI18n.closeTitle
    closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

    topTrailingStack.axis = .horizontal
    topTrailingStack.spacing = 8
    topTrailingStack.alignment = .center

    [closeButton, topTrailingStack].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      closeButton.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 8),
      closeButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      closeButton.widthAnchor.constraint(equalToConstant: 44),
      closeButton.heightAnchor.constraint(equalToConstant: 44),
      closeButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
      topTrailingStack.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
      topTrailingStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(configuration: FKMediaGalleryChromeConfiguration) {
    closeButton.isHidden = !configuration.showsCloseButton
    setShareButtonVisible(configuration.showsShareButton)
  }

  func updatePageIndicator(
    currentIndex: Int,
    total: Int,
    item: FKMediaGalleryItem,
    style: FKMediaGalleryPageIndicatorStyle
  ) {
    guard total > 1 else {
      hidePageIndicator()
      return
    }
    let resolvedStyle: FKMediaGalleryPageIndicatorStyle = style == .dots && total > 10 ? .numeric : style
    switch resolvedStyle {
    case .numeric:
      hideDotsIndicator()
      let label = ensurePageLabel()
      label.isHidden = false
      if FKMediaGalleryItemResolver.isVideo(item) {
        label.text = FKMediaGalleryI18n.videoPageIndicator(current: currentIndex + 1, total: total)
      } else if FKMediaGalleryItemResolver.isLivePhoto(item) {
        label.text = FKMediaGalleryI18n.livePhotoPageIndicator(current: currentIndex + 1, total: total)
      } else {
        label.text = FKMediaGalleryI18n.photoPageIndicator(current: currentIndex + 1, total: total)
      }
    case .dots:
      hidePageLabel()
      let stack = ensureDotsStack()
      stack.isHidden = false
      updateDots(current: currentIndex, total: total)
    case .none:
      hidePageIndicator()
    }
  }

  func setMuted(_ muted: Bool) {
    isMuted = muted
    guard let muteButton else { return }
    let symbol = muted ? "speaker.slash.fill" : "speaker.wave.2.fill"
    muteButton.setImage(UIImage(systemName: symbol), for: .normal)
    muteButton.accessibilityLabel = muted ? FKMediaGalleryI18n.unmuteTitle : FKMediaGalleryI18n.muteTitle
  }

  func setMuteButtonVisible(_ visible: Bool) {
    if visible {
      ensureMuteButton()
    } else {
      removeMuteButton()
    }
  }

  func setShareButtonVisible(_ visible: Bool) {
    if visible {
      ensureShareButton()
    } else {
      removeShareButton()
    }
  }

  // MARK: - Private

  private func hidePageIndicator() {
    hidePageLabel()
    hideDotsIndicator()
  }

  private func ensurePageLabel() -> UILabel {
    if let pageLabel { return pageLabel }
    let label = UILabel()
    label.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
    label.textColor = .white
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    NSLayoutConstraint.activate([
      label.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
      label.centerXAnchor.constraint(equalTo: centerXAnchor),
    ])
    pageLabel = label
    return label
  }

  private func hidePageLabel() {
    pageLabel?.isHidden = true
  }

  private func ensureDotsStack() -> UIStackView {
    if let dotsStack { return dotsStack }
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 6
    stack.alignment = .center
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)
    NSLayoutConstraint.activate([
      stack.centerXAnchor.constraint(equalTo: centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
    ])
    dotsStack = stack
    return stack
  }

  private func hideDotsIndicator() {
    dotsStack?.isHidden = true
  }

  private func updateDots(current: Int, total: Int) {
    let stack = ensureDotsStack()
    while dotViews.count < total {
      let dot = UIView()
      dot.layer.cornerRadius = 4
      dot.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        dot.widthAnchor.constraint(equalToConstant: 8),
        dot.heightAnchor.constraint(equalToConstant: 8),
      ])
      dotViews.append(dot)
      stack.addArrangedSubview(dot)
    }
    for (index, dot) in dotViews.enumerated() {
      let isActive = index < total
      dot.isHidden = !isActive
      guard isActive else { continue }
      dot.backgroundColor = index == current ? UIColor.white : UIColor.white.withAlphaComponent(0.35)
    }
  }

  private func ensureShareButton() {
    guard shareButton == nil else { return }
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
    button.tintColor = .white
    button.accessibilityLabel = FKMediaGalleryI18n.shareTitle
    button.addTarget(self, action: #selector(shareTapped), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.widthAnchor.constraint(equalToConstant: 44),
      button.heightAnchor.constraint(equalToConstant: 44),
    ])
    shareButton = button
    topTrailingStack.insertArrangedSubview(button, at: 0)
  }

  private func removeShareButton() {
    guard let shareButton else { return }
    topTrailingStack.removeArrangedSubview(shareButton)
    shareButton.removeFromSuperview()
    self.shareButton = nil
  }

  private func ensureMuteButton() {
    guard muteButton == nil else { return }
    let button = UIButton(type: .system)
    button.tintColor = .white
    button.addTarget(self, action: #selector(muteTapped), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      button.widthAnchor.constraint(equalToConstant: 44),
      button.heightAnchor.constraint(equalToConstant: 44),
    ])
    muteButton = button
    topTrailingStack.addArrangedSubview(button)
    setMuted(isMuted)
  }

  private func removeMuteButton() {
    guard let muteButton else { return }
    topTrailingStack.removeArrangedSubview(muteButton)
    muteButton.removeFromSuperview()
    self.muteButton = nil
  }

  @objc private func closeTapped() { onClose?() }
  @objc private func shareTapped() { onShare?() }
  @objc private func muteTapped() { onMuteToggle?() }
}

/// Bottom caption chrome; only occupies the caption band above the safe area.
@MainActor
final class FKMediaGalleryBottomCaptionView: UIView {
  private let captionLabel = UILabel()
  private var captionBottomConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    isUserInteractionEnabled = false

    captionLabel.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 14))
    captionLabel.textColor = UIColor.white.withAlphaComponent(0.92)
    captionLabel.numberOfLines = 0
    captionLabel.textAlignment = .center
    captionLabel.translatesAutoresizingMaskIntoConstraints = false
    addSubview(captionLabel)

    NSLayoutConstraint.activate([
      captionLabel.topAnchor.constraint(equalTo: topAnchor),
      captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
      captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
    ])
    captionBottomConstraint = captionLabel.bottomAnchor.constraint(
      equalTo: safeAreaLayoutGuide.bottomAnchor,
      constant: -16
    )
    captionBottomConstraint?.isActive = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(showsCaption: Bool) {
    captionLabel.isHidden = !showsCaption
  }

  func updateCaption(_ caption: String?) {
    captionLabel.text = caption
    captionLabel.isHidden = caption?.isEmpty ?? true
  }

  func setBottomInset(_ inset: CGFloat) {
    captionBottomConstraint?.constant = -inset
  }
}

/// Pairs compact top and bottom chrome views; no full-screen overlay wrapper.
@MainActor
final class FKMediaGalleryChrome {
  let topBar = FKMediaGalleryTopChromeView()
  let bottomBar = FKMediaGalleryBottomCaptionView()

  private var hideWorkItem: DispatchWorkItem?

  var shareAnchorView: UIView { topBar.shareAnchorView }

  func install(in container: UIView) {
    topBar.translatesAutoresizingMaskIntoConstraints = false
    bottomBar.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(topBar)
    container.addSubview(bottomBar)
    NSLayoutConstraint.activate([
      topBar.topAnchor.constraint(equalTo: container.topAnchor),
      topBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      topBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      bottomBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      bottomBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      bottomBar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
  }

  func apply(configuration: FKMediaGalleryChromeConfiguration) {
    topBar.apply(configuration: configuration)
    bottomBar.apply(showsCaption: configuration.showsCaption)
    scheduleAutoHide(after: configuration.chromeAutoHideInterval)
  }

  func updatePageIndicator(
    currentIndex: Int,
    total: Int,
    item: FKMediaGalleryItem,
    style: FKMediaGalleryPageIndicatorStyle
  ) {
    topBar.updatePageIndicator(currentIndex: currentIndex, total: total, item: item, style: style)
  }

  func updateCaption(_ caption: String?) {
    bottomBar.updateCaption(caption)
  }

  func setCaptionBottomInset(_ inset: CGFloat) {
    bottomBar.setBottomInset(inset)
  }

  func setMuteButtonVisible(_ visible: Bool) {
    topBar.setMuteButtonVisible(visible)
  }

  func setMuted(_ muted: Bool) {
    topBar.setMuted(muted)
  }

  func setChromeVisible(_ visible: Bool, animated: Bool) {
    hideWorkItem?.cancel()
    let alpha: CGFloat = visible ? 1 : 0
    topBar.isUserInteractionEnabled = visible
    let updates = {
      self.topBar.alpha = alpha
      self.bottomBar.alpha = alpha
    }
    if animated {
      UIView.animate(withDuration: 0.2, animations: updates)
    } else {
      updates()
    }
  }

  private func scheduleAutoHide(after interval: TimeInterval?) {
    hideWorkItem?.cancel()
    guard let interval, interval > 0 else { return }
    let work = DispatchWorkItem { [weak self] in
      self?.setChromeVisible(false, animated: true)
    }
    hideWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: work)
  }
}
