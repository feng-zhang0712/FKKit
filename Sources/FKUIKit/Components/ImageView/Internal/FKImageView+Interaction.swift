import UIKit

extension FKImageView {
  var allowsFailureTapToRetry: Bool {
    if case .failure = state,
      configuration.failure.isRetryEnabled,
      configuration.failure.retryButtonTitle == nil
    {
      return true
    }
    return false
  }

  func refreshTapGesture() {
    if let tapRecognizer {
      removeGestureRecognizer(tapRecognizer)
      self.tapRecognizer = nil
    }
    if let pressRecognizer {
      removeGestureRecognizer(pressRecognizer)
      self.pressRecognizer = nil
    }

    let usesHighlight = configuration.interaction.highlightOnPress
      || configuration.appearance.adjustsImageWhenHighlighted
    guard onTap != nil || usesHighlight || allowsFailureTapToRetry else { return }

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    addGestureRecognizer(tap)
    tapRecognizer = tap

    if usesHighlight {
      let press = UILongPressGestureRecognizer(target: self, action: #selector(handlePress(_:)))
      press.minimumPressDuration = 0
      press.cancelsTouchesInView = false
      addGestureRecognizer(press)
      pressRecognizer = press
    }
  }

  @objc func handleTap() {
    if case .failure = state, configuration.failure.isRetryEnabled,
      configuration.failure.retryButtonTitle == nil
    {
      retry()
      return
    }
    onTap?()
  }

  @objc func handlePress(_ recognizer: UILongPressGestureRecognizer) {
    let usesHighlight = configuration.interaction.highlightOnPress
      || configuration.appearance.adjustsImageWhenHighlighted
    guard usesHighlight else { return }
    switch recognizer.state {
    case .began:
      imageView.alpha = configuration.appearance.highlightedAlpha
    case .ended, .cancelled, .failed:
      imageView.alpha = 1
    default:
      break
    }
  }

  func updateAccessibility() {
    if configuration.accessibility.isDecorative {
      let hidesFromAccessibility: Bool = {
        switch state {
        case .placeholder:
          return true
        case .idle:
          return configuration.loading.showsPlaceholderWhenIdle
        default:
          return false
        }
      }()
      if hidesFromAccessibility {
        accessibilityElementsHidden = true
        isAccessibilityElement = false
        return
      }
    }

    accessibilityElementsHidden = false
    isAccessibilityElement = true

    switch state {
    case .idle:
      accessibilityLabel = configuration.accessibility.label
        ?? configuration.accessibility.imageDescription
      accessibilityTraits = .image
      accessibilityHint = nil
    case .placeholder, .loading:
      accessibilityLabel = configuration.accessibility.label
        ?? configuration.accessibility.imageDescription
        ?? FKUIKitI18n.string("fkuikit.common.loading")
      accessibilityTraits = .image
      accessibilityHint = nil
    case .success:
      accessibilityLabel = configuration.accessibility.label
        ?? configuration.accessibility.imageDescription
      accessibilityTraits = onTap == nil ? .image : [.image, .button]
      accessibilityHint = nil
    case .failure(let reason):
      accessibilityLabel = configuration.accessibility.label
        ?? configuration.failure.resolvedMessage(for: reason)
      if configuration.failure.isRetryEnabled {
        accessibilityTraits = .button
        accessibilityHint = configuration.failure.resolvedRetryTitle
      } else {
        accessibilityTraits = .image
        accessibilityHint = nil
      }
    }
  }
}
