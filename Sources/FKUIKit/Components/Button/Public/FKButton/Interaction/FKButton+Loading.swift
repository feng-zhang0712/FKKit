import UIKit

extension FKButton {
  // MARK: - Loading

  /// Shows the loading chrome, blocks interaction, and optionally updates `loadingPresentationStyle` for this transition.
  public func setLoading(_ loading: Bool, presentation: LoadingPresentationStyle? = nil) {
    guard loading != isLoading else { return }
    if let p = presentation {
      loadingPresentationStyle = p
    }
    if loading {
      dismissTransientResultIfNeeded(animated: false)
      userInteractionEnabledBeforeLoading = isUserInteractionEnabled
      if loadingPreservesIntrinsicWidth {
        intrinsicWidthPinnedForLoading = intrinsicContentSize.width
      }
      isLoading = true
      isUserInteractionEnabled = false
      installLoadingOverlayIfNeeded()
      syncLoadingIndicatorConfiguration()
      applyLoadingChromeForCurrentStyle()
      loadingOverlayHost.isHidden = false
      loadingIndicator.startAnimating()
    } else {
      isLoading = false
      intrinsicWidthPinnedForLoading = nil
      isUserInteractionEnabled = userInteractionEnabledBeforeLoading
      loadingIndicator.stopAnimating()
      stackView.isHidden = false
      stackView.alpha = 1
      loadingMessageLabel.text = nil
      loadingMessageLabel.isHidden = true
      uninstallLoadingOverlayFromHierarchy()
    }
    requestVisualRefresh()
  }

  /// Updates loading visuals while already loading (or stores the style for the next `setLoading(true)`).
  public func applyLoadingPresentation(_ style: LoadingPresentationStyle) {
    loadingPresentationStyle = style
    if isLoading {
      applyLoadingChromeForCurrentStyle()
    }
  }

  /// Runs `operation` with loading enabled, then restores interaction and any temporary `presentation` override.
  @MainActor
  public func performWhileLoading(
    presentation: LoadingPresentationStyle? = nil,
    operation: () async throws -> Void
  ) async rethrows {
    let previousStyle = loadingPresentationStyle
    if let p = presentation {
      loadingPresentationStyle = p
    }
    setLoading(true)
    defer {
      setLoading(false)
      loadingPresentationStyle = previousStyle
    }
    try await operation()
  }

  // MARK: - Loading overlay (internal views)

  func configureLoadingOverlay() {
    loadingOverlayHost.isUserInteractionEnabled = false
    loadingOverlayHost.backgroundColor = .clear
    loadingOverlayHost.translatesAutoresizingMaskIntoConstraints = false
    loadingOverlayHost.isHidden = true

    loadingRowStack.axis = .horizontal
    loadingRowStack.alignment = .center
    loadingRowStack.spacing = 8
    loadingRowStack.isUserInteractionEnabled = false
    loadingRowStack.translatesAutoresizingMaskIntoConstraints = false

    loadingMessageLabel.numberOfLines = 1
    loadingMessageLabel.textAlignment = .natural
    loadingMessageLabel.lineBreakMode = .byTruncatingTail
    loadingMessageLabel.isHidden = true

    loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
    loadingIndicator.hidesWhenStopped = true
    syncLoadingIndicatorConfiguration()

    loadingRowStack.addArrangedSubview(loadingIndicator)
    loadingRowStack.addArrangedSubview(loadingMessageLabel)

    loadingOverlayHost.addSubview(loadingRowStack)
    NSLayoutConstraint.activate([
      loadingRowStack.centerXAnchor.constraint(equalTo: loadingOverlayHost.centerXAnchor),
      loadingRowStack.centerYAnchor.constraint(equalTo: loadingOverlayHost.centerYAnchor),
    ])
  }

  /// Pins `loadingOverlayHost` to the button and places it above the content stack. Call only from `setLoading(true)`.
  func installLoadingOverlayIfNeeded() {
    guard loadingOverlayHost.superview == nil else { return }
    insertSubview(loadingOverlayHost, aboveSubview: contentContainerView)
    loadingOverlayLayoutConstraints = [
      loadingOverlayHost.topAnchor.constraint(equalTo: topAnchor),
      loadingOverlayHost.leadingAnchor.constraint(equalTo: leadingAnchor),
      loadingOverlayHost.trailingAnchor.constraint(equalTo: trailingAnchor),
      loadingOverlayHost.bottomAnchor.constraint(equalTo: bottomAnchor),
    ]
    NSLayoutConstraint.activate(loadingOverlayLayoutConstraints)
  }

  /// Removes loading chrome from the hierarchy until the next `setLoading(true)`.
  func uninstallLoadingOverlayFromHierarchy() {
    NSLayoutConstraint.deactivate(loadingOverlayLayoutConstraints)
    loadingOverlayLayoutConstraints.removeAll()
    loadingOverlayHost.removeFromSuperview()
  }

  func syncLoadingIndicatorConfiguration() {
    loadingIndicator.style = loadingIndicatorConfiguration.style
    loadingIndicator.color = loadingIndicatorConfiguration.color
    let scale = loadingIndicatorConfiguration.scale
    loadingIndicator.transform = scale == 1 ? .identity : CGAffineTransform(scaleX: scale, y: scale)
  }

  func applyLoadingChromeForCurrentStyle() {
    switch loadingPresentationStyle {
    case .overlay(let dimmed):
      stackView.isHidden = false
      stackView.alpha = max(0, min(1, dimmed))
      loadingMessageLabel.text = nil
      loadingMessageLabel.isHidden = true
      accessibilityValue = nil
    case .replacesContent(let options):
      stackView.isHidden = true
      stackView.alpha = 1
      loadingRowStack.spacing = max(0, options.spacingAfterIndicator)
      let trimmed = options.message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      if trimmed.isEmpty {
        loadingMessageLabel.isHidden = true
        loadingMessageLabel.text = nil
        accessibilityValue = nil
      } else {
        loadingMessageLabel.isHidden = false
        loadingMessageLabel.text = options.message
        loadingMessageLabel.font = options.messageFont
        loadingMessageLabel.textColor = options.messageColor
        accessibilityValue = trimmed
      }
    }
  }

  // MARK: - Transient result

  /// Presents a brief success, failure, or custom result state, then restores the previous visuals.
  ///
  /// - Note: Does not run while `isLoading` is `true`. Cancels any in-flight transient result.
  @MainActor
  public func showTransientResult(
    _ result: FKButtonTransientResult,
    duration: TimeInterval = 1.2,
    options: FKButtonTransientResultOptions = .default
  ) async {
    guard !isLoading else { return }
    dismissTransientResultIfNeeded(animated: false)

    let clampedDuration = max(0.3, duration)
    userInteractionEnabledBeforeTransientResult = isUserInteractionEnabled
    isPresentingTransientResult = true
    if options.blocksInteraction {
      isUserInteractionEnabled = false
    }

    installLoadingOverlayIfNeeded()
    loadingIndicator.stopAnimating()
    loadingIndicator.isHidden = true
    stackView.isHidden = true
    stackView.alpha = 1
    loadingOverlayHost.isHidden = false
    loadingRowStack.spacing = 8

    let (symbolName, tint, defaultMessage) = resolvedTransientResultContent(for: result)
    let message = resolvedTransientResultMessage(
      for: result,
      options: options,
      defaultMessage: defaultMessage
    )

    if let image = UIImage(systemName: symbolName) {
      loadingMessageLabel.isHidden = false
      let attachment = NSTextAttachment()
      attachment.image = image.withTintColor(tint, renderingMode: .alwaysOriginal)
      let iconSize = loadingIndicatorConfiguration.style == .large ? 22 : 18
      attachment.bounds = CGRect(x: 0, y: -4, width: iconSize, height: iconSize)
      let prefix = NSAttributedString(attachment: attachment)
      let text = NSMutableAttributedString(attributedString: prefix)
      if let message, !message.isEmpty {
        text.append(NSAttributedString(string: " \(message)", attributes: [
          .font: options.messageFont,
          .foregroundColor: options.messageColor,
        ]))
      }
      loadingMessageLabel.attributedText = text
      loadingMessageLabel.font = options.messageFont
      accessibilityValue = message ?? defaultMessage
    }

    applyHighlightVisuals(animated: false)
    requestVisualRefresh()

    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      transientResultDismissTimer?.invalidate()
      let timer = Timer(timeInterval: clampedDuration, repeats: false) { [weak self] _ in
        Task { @MainActor in
          self?.dismissTransientResultIfNeeded(animated: true)
          continuation.resume()
        }
      }
      RunLoop.main.add(timer, forMode: .common)
      transientResultDismissTimer = timer
    }
  }

  func dismissTransientResultIfNeeded(animated: Bool) {
    guard isPresentingTransientResult else { return }
    transientResultDismissTimer?.invalidate()
    transientResultDismissTimer = nil
    isPresentingTransientResult = false
    loadingIndicator.isHidden = false
    loadingMessageLabel.attributedText = nil
    loadingMessageLabel.text = nil
    loadingMessageLabel.isHidden = true
    accessibilityValue = nil
    stackView.isHidden = false
    stackView.alpha = 1
    uninstallLoadingOverlayFromHierarchy()
    isUserInteractionEnabled = userInteractionEnabledBeforeTransientResult
    requestVisualRefresh()
    if animated {
      UIView.transition(with: self, duration: 0.15, options: .transitionCrossDissolve) {}
    }
  }

  func resolvedTransientResultContent(for result: FKButtonTransientResult) -> (symbolName: String, tint: UIColor, defaultMessage: String) {
    switch result {
    case .success:
      return ("checkmark.circle.fill", .systemGreen, FKUIKitI18n.string("fkuikit.button.success"))
    case .failure:
      return ("xmark.circle.fill", .systemRed, FKUIKitI18n.string("fkuikit.button.failed"))
    case .custom(let systemName, let tintColor, _):
      return (systemName, tintColor, "")
    }
  }

  func resolvedTransientResultMessage(
    for result: FKButtonTransientResult,
    options: FKButtonTransientResultOptions,
    defaultMessage: String
  ) -> String? {
    if let optionsMessage = options.message?.trimmingCharacters(in: .whitespacesAndNewlines), !optionsMessage.isEmpty {
      return optionsMessage
    }
    switch result {
    case .custom(_, _, let message):
      let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
      return trimmed.isEmpty ? nil : trimmed
    case .success, .failure:
      return defaultMessage
    }
  }
}
