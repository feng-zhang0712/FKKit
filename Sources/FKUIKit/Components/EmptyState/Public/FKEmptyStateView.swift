import UIKit

// MARK: - Delegate

/// Delegate for action button taps (alternative to `actionHandler` closure).
public protocol FKEmptyStateViewDelegate: AnyObject {
  /// Called when the user taps an action button.
  ///
  /// - Important: The callback carries a full `FKEmptyStateAction` so hosts can route by `id`
  ///   (recommended) or by `kind` (UI slot role).
  func emptyStateView(_ view: FKEmptyStateView, didTap action: FKEmptyStateAction)
}

// MARK: - FKEmptyStateView

/// Full-screen overlay for empty, loading, error, or custom-state UI.
///
/// Prefer adding to `UIViewController.view` or a `UIScrollView` subview — **not** `UITableView.backgroundView`, so refresh controls remain visible above table backgrounds.
///
/// Touch handling: the view fills the host bounds and intercepts touches; `UIGestureRecognizerDelegate` avoids stealing taps from `UIControl` subclasses (e.g. the action button). Optional dimming uses `appearance.background.blockingOverlayAlpha`.
///
/// Accessibility notes:
/// - The overlay does not set `accessibilityViewIsModal` by default to avoid trapping focus in
///   complex screens. Instead, it posts a VoiceOver announcement on state changes when
///   `FKEmptyStateConfiguration.presentation.announcesStateChanges` is enabled.
/// - Title is marked as `.header` to improve navigation in VoiceOver rotor.
public final class FKEmptyStateView: UIView, UIGestureRecognizerDelegate {

  // MARK: Public

  /// Optional delegate for button taps.
  public weak var delegate: FKEmptyStateViewDelegate?
  /// Closure invoked when any action button is tapped (primary / secondary / tertiary).
  ///
  /// Use `action.id` as a stable routing key.
  public var actionHandler: ((FKEmptyStateAction) -> Void)?
  /// Closure invoked when users tap the placeholder background area.
  public var viewTapHandler: FKVoidHandler?
  /// Snapshot of the last `apply(_:animated:)` input (for debugging / re-application).
  public private(set) var configuration: FKEmptyStateConfiguration = FKEmptyStateConfiguration()

  // MARK: Private (subviews & state)

  /// Full-bleed dimming layer between gradient and content (`appearance.background.blockingOverlayAlpha`).
  private let blockingDimmingView = UIView()
  /// Horizontal + vertical centering container for the stack (respects safe area & keyboard).
  private let containerView = UIView()
  /// Vertical stack for illustration, text, spinner, and button.
  private let stackView = UIStackView()
  /// Illustration + text row used when ``FKEmptyStateLayoutConfiguration/axis`` is `.horizontal`.
  private let horizontalRowStack = UIStackView()
  private let horizontalTextStack = UIStackView()
  /// Hosts ``FKEmptyStateContentConfiguration/customAccessory`` when provided.
  private let customAccessoryContainer = UIView()
  private let imageView = UIImageView()
  private let titleLabel = UILabel()
  private let descriptionLabel = UILabel()
  private let primaryButton = UIButton(type: .system)
  private let secondaryButton = UIButton(type: .system)
  private let tertiaryButton = UIButton(type: .system)
  private let actionsStack = UIStackView()
  private let headerSlotContainer = UIView()
  private let mediaSlotContainer = UIView()
  private let contentSlotContainer = UIView()
  private let actionsSlotContainer = UIView()
  private let footerSlotContainer = UIView()
  private var loadingIndicator = UIActivityIndicatorView(style: .large)
  /// Tracks style to avoid recreating the indicator unnecessarily.
  private var appliedIndicatorStyle: UIActivityIndicatorView.Style?
  /// Background tap → `endEditing(true)` when `supportsTapToDismissKeyboard` is enabled.
  private let keyboardDismissTap = UITapGestureRecognizer()
  private var gradientLayer: CAGradientLayer?
  private var imageWidthConstraint: NSLayoutConstraint?
  private var imageHeightConstraint: NSLayoutConstraint?
  private var containerMaxWidthConstraint: NSLayoutConstraint?
  private var keyboardBottomConstraint: NSLayoutConstraint?
  private var containerCenterYToSafeAreaConstraint: NSLayoutConstraint?
  private var containerCenterXToSafeAreaConstraint: NSLayoutConstraint?
  private var containerCenterYToBoundsConstraint: NSLayoutConstraint?
  private var containerCenterXToBoundsConstraint: NSLayoutConstraint?
  private var containerTopConstraint: NSLayoutConstraint?
  private var lastAnnouncementSignature: String?

  // MARK: Lifecycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupViews()
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer?.frame = bounds
  }

  public override func didMoveToSuperview() {
    super.didMoveToSuperview()
    updateScrollViewportAnchoring()
  }

  // MARK: Public API

  /// Applies `configuration` to labels, images, spinner, and layout. Must run on the main thread.
  ///
  /// - Parameters:
  ///   - configuration: New configuration; `phase == .content` is a no-op visually (caller should hide the overlay).
  ///   - animated: Runs ``FKEmptyStatePresentationConfiguration/transition`` when `true` (Reduce Motion applies updates instantly).
  public func apply(_ configuration: FKEmptyStateConfiguration, animated: Bool = false) {
    fk_emptyStateAssertMainThread()
    self.configuration = configuration
    let updates = { self.updateUI(with: configuration) }
    if animated, !UIAccessibility.isReduceMotionEnabled, configuration.presentation.transition != .none {
      performContentTransition(configuration: configuration, updates: updates)
    } else {
      updates()
    }
  }

  private func prepareContainerForTransition() {
    containerView.layer.removeAllAnimations()
    stackView.layer.removeAllAnimations()
    containerView.transform = .identity
    containerView.alpha = 1
  }

  private func performContentTransition(configuration: FKEmptyStateConfiguration, updates: @escaping () -> Void) {
    prepareContainerForTransition()
    let duration = configuration.presentation.fadeDuration
    switch configuration.presentation.transition {
    case .none:
      updates()
    case .crossDissolve:
      let snapshot = containerView.snapshotView(afterScreenUpdates: false)
      updates()
      containerView.layoutIfNeeded()
      guard let snapshot else { return }
      snapshot.frame = containerView.bounds
      snapshot.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      containerView.addSubview(snapshot)
      UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState], animations: {
        snapshot.alpha = 0
      }, completion: { _ in
        snapshot.removeFromSuperview()
      })
    case .fade:
      UIView.animate(withDuration: duration * 0.5, animations: {
        self.containerView.alpha = 0
      }, completion: { _ in
        updates()
        UIView.animate(withDuration: duration * 0.5) {
          self.containerView.alpha = 1
        }
      })
    case .scale:
      containerView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
      containerView.alpha = 0
      updates()
      containerView.layoutIfNeeded()
      UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
        self.containerView.transform = .identity
        self.containerView.alpha = 1
      })
    case .slideUp:
      containerView.transform = CGAffineTransform(translationX: 0, y: 24)
      containerView.alpha = 0
      updates()
      containerView.layoutIfNeeded()
      UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
        self.containerView.transform = .identity
        self.containerView.alpha = 1
      })
    }
  }

  /// Manually assigns a custom illustration view (e.g. Lottie). `nil` clears the container.
  public func setCustomAccessoryView(_ view: UIView?) {
    fk_emptyStateAssertMainThread()
    customAccessoryContainer.subviews.forEach { $0.removeFromSuperview() }
    guard let view else {
      customAccessoryContainer.isHidden = true
      return
    }
    view.translatesAutoresizingMaskIntoConstraints = false
    customAccessoryContainer.addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: customAccessoryContainer.topAnchor),
      view.leadingAnchor.constraint(equalTo: customAccessoryContainer.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: customAccessoryContainer.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: customAccessoryContainer.bottomAnchor),
    ])
    customAccessoryContainer.isHidden = false
  }

  // MARK: Setup

  private func setupViews() {
    isHidden = true
    alpha = 0
    isUserInteractionEnabled = true
    accessibilityIdentifier = "fk.emptyState.root"

    blockingDimmingView.translatesAutoresizingMaskIntoConstraints = false
    blockingDimmingView.isUserInteractionEnabled = false
    addSubview(blockingDimmingView)

    containerView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(containerView)

    stackView.axis = .vertical
    stackView.alignment = .center
    stackView.distribution = .fill
    stackView.spacing = 10
    stackView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(stackView)

    horizontalRowStack.translatesAutoresizingMaskIntoConstraints = false
    horizontalRowStack.isHidden = true
    horizontalTextStack.axis = .vertical
    horizontalTextStack.alignment = .leading
    horizontalTextStack.spacing = 8
    horizontalTextStack.translatesAutoresizingMaskIntoConstraints = false

    customAccessoryContainer.translatesAutoresizingMaskIntoConstraints = false

    imageView.contentMode = .scaleAspectFit
    imageView.setContentCompressionResistancePriority(.required, for: .vertical)
    imageView.accessibilityIdentifier = "fk.emptyState.image"
    imageView.isAccessibilityElement = false

    titleLabel.numberOfLines = 0
    titleLabel.textAlignment = .center
    titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    titleLabel.accessibilityIdentifier = "fk.emptyState.title"
    titleLabel.isAccessibilityElement = true
    titleLabel.accessibilityTraits = [.header]

    descriptionLabel.numberOfLines = 0
    descriptionLabel.textAlignment = .center
    descriptionLabel.accessibilityIdentifier = "fk.emptyState.description"
    descriptionLabel.isAccessibilityElement = true

    actionsStack.axis = .vertical
    actionsStack.alignment = .center
    actionsStack.distribution = .fill
    actionsStack.spacing = 10
    actionsStack.translatesAutoresizingMaskIntoConstraints = false
    actionsStack.accessibilityIdentifier = "fk.emptyState.actions"

    configureButton(primaryButton, identifier: "fk.emptyState.primaryButton", action: #selector(handlePrimaryTap))
    configureButton(secondaryButton, identifier: "fk.emptyState.secondaryButton", action: #selector(handleSecondaryTap))
    configureButton(tertiaryButton, identifier: "fk.emptyState.tertiaryButton", action: #selector(handleTertiaryTap))

    headerSlotContainer.translatesAutoresizingMaskIntoConstraints = false
    mediaSlotContainer.translatesAutoresizingMaskIntoConstraints = false
    contentSlotContainer.translatesAutoresizingMaskIntoConstraints = false
    actionsSlotContainer.translatesAutoresizingMaskIntoConstraints = false
    footerSlotContainer.translatesAutoresizingMaskIntoConstraints = false

    loadingIndicator.hidesWhenStopped = true
    loadingIndicator.accessibilityIdentifier = "fk.emptyState.loading"
    loadingIndicator.isAccessibilityElement = true

    keyboardDismissTap.addTarget(self, action: #selector(handleBackgroundTap))
    keyboardDismissTap.cancelsTouchesInView = false
    keyboardDismissTap.delegate = self
    addGestureRecognizer(keyboardDismissTap)

    containerMaxWidthConstraint = containerView.widthAnchor.constraint(lessThanOrEqualToConstant: 320)
    containerMaxWidthConstraint?.isActive = true

    let centerYToSafeArea = containerView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor)
    centerYToSafeArea.priority = UILayoutPriority(750)
    centerYToSafeArea.isActive = true
    containerCenterYToSafeAreaConstraint = centerYToSafeArea

    let centerYToBounds = containerView.centerYAnchor.constraint(equalTo: centerYAnchor)
    centerYToBounds.priority = UILayoutPriority(750)
    centerYToBounds.isActive = false
    containerCenterYToBoundsConstraint = centerYToBounds

    let centerXToSafeArea = containerView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor)
    centerXToSafeArea.isActive = true
    containerCenterXToSafeAreaConstraint = centerXToSafeArea

    let centerXToBounds = containerView.centerXAnchor.constraint(equalTo: centerXAnchor)
    centerXToBounds.isActive = false
    containerCenterXToBoundsConstraint = centerXToBounds

    let topConstraint = containerView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor)
    topConstraint.priority = UILayoutPriority(500)
    topConstraint.isActive = false
    containerTopConstraint = topConstraint

    NSLayoutConstraint.activate([
      blockingDimmingView.topAnchor.constraint(equalTo: topAnchor),
      blockingDimmingView.leadingAnchor.constraint(equalTo: leadingAnchor),
      blockingDimmingView.trailingAnchor.constraint(equalTo: trailingAnchor),
      blockingDimmingView.bottomAnchor.constraint(equalTo: bottomAnchor),

      containerView.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
      containerView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),

      stackView.topAnchor.constraint(equalTo: containerView.topAnchor),
      stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    let keyboardBottom = containerView.bottomAnchor.constraint(lessThanOrEqualTo: keyboardLayoutGuide.topAnchor, constant: -12)
    keyboardBottom.priority = .required
    keyboardBottom.isActive = true
    keyboardBottomConstraint = keyboardBottom
  }

  private func configureButton(_ button: UIButton, identifier: String, action: Selector) {
    button.addTarget(self, action: action, for: .touchUpInside)
    button.titleLabel?.numberOfLines = 1
    button.accessibilityIdentifier = identifier
    button.isAccessibilityElement = true
  }

  // MARK: UI update

  private func updateUI(with model: FKEmptyStateConfiguration) {
    let resolved = FKEmptyStateResolvedLayout(configuration: model)
    let metrics = FKEmptyStateLayoutMetrics(density: model.layout.density)

    backgroundColor = model.appearance.background.color
    updateGradient(with: model)

    blockingDimmingView.backgroundColor = UIColor.black.withAlphaComponent(model.appearance.background.blockingOverlayAlpha)

    stackView.spacing = metrics.spacing(from: resolved.verticalSpacing)
    actionsStack.spacing = metrics.spacing(from: resolved.verticalSpacing)
    containerMaxWidthConstraint?.constant = resolved.maxContentWidth

    let insets = resolved.contentInsets
    directionalLayoutMargins = NSDirectionalEdgeInsets(
      top: insets.top,
      leading: insets.left,
      bottom: insets.bottom,
      trailing: insets.right
    )

    // Recreate the activity indicator only when style changes.
    // This avoids unnecessary view churn while still supporting dynamic style switching.
    if appliedIndicatorStyle != model.appearance.loading.style {
      loadingIndicator.removeFromSuperview()
      loadingIndicator = UIActivityIndicatorView(style: model.appearance.loading.style)
      loadingIndicator.hidesWhenStopped = true
      appliedIndicatorStyle = model.appearance.loading.style
    }

    syncCustomAccessoryIfNeeded(model: model)

    applyImagePresentation(model: model)
    applyImageConstraints(imageSize: resolved.imageSize)

    titleLabel.textColor = model.appearance.typography.titleColor
    titleLabel.font = metrics.titleFont(from: model.appearance.typography.titleFont)
    descriptionLabel.textColor = model.appearance.typography.descriptionColor
    descriptionLabel.font = metrics.descriptionFont(from: model.appearance.typography.descriptionFont)
    titleLabel.textAlignment = model.appearance.typography.textAlignment
    descriptionLabel.textAlignment = model.appearance.typography.textAlignment

    // Allow forcing layout direction for QA/preview (e.g. RTL verification).
    // When unset, the view follows system direction.
    if let forced = model.layout.forcedLayoutDirection {
      semanticContentAttribute = (forced == .rightToLeft) ? .forceRightToLeft : .forceLeftToRight
    } else {
      semanticContentAttribute = .unspecified
    }

    switch model.phase {
    case .content:
      break
    case .loading:
      applyLoadingPhase(model: model)
    case .empty, .error, .custom:
      applyContentPhase(model: model, resolved: resolved)
    }

    // Background tap dismisses keyboard when enabled; `viewTapHandler` can register independently.
    // The gesture recognizer will not steal taps from buttons/controls due to `gestureRecognizer(_:shouldReceive:)`.
    keyboardDismissTap.isEnabled = model.presentation.supportsTapToDismissKeyboard || viewTapHandler != nil
    // Keyboard-aware positioning is implemented via `keyboardLayoutGuide` when enabled.
    keyboardBottomConstraint?.isActive = model.presentation.adjustsPositionForKeyboard
    updateContentPosition(resolved: resolved, model: model)

    applySlots(model: model)
    refreshSlotContainerVisibility()
    applySegmentSpacing(model: model, resolved: resolved)
    applyAccessibility(model: model)
    announceIfNeeded(model: model)
  }

  // MARK: Loading layout

  private func applyLoadingPhase(model: FKEmptyStateConfiguration) {
    let message = model.content.loadingMessage ?? model.content.title
    titleLabel.text = message
    titleLabel.isHidden = message?.isEmpty != false
    let showDesc = !model.presentation.loadingBehavior.hidesDescription && !(model.content.description?.isEmpty ?? true)
    descriptionLabel.text = model.content.description
    descriptionLabel.isHidden = !showDesc

    if model.presentation.loadingBehavior.hidesImage {
      imageView.isHidden = true
      customAccessoryContainer.isHidden = true
    } else {
      applyImageVisibility(model: model)
    }

    loadingIndicator.color = model.appearance.loading.tintColor
    loadingIndicator.startAnimating()

    actionsStack.isHidden = true

    rebuildStack(orderedViews: loadingBlocks(model: model))
  }

  /// Stack order for the loading phase; respects ``FKEmptyStateLoadingBehavior/hidesImage``.
  private func loadingBlocks(model: FKEmptyStateConfiguration) -> [UIView] {
    detachLabelsFromHorizontalRow()
    horizontalRowStack.isHidden = true

    let tail: [UIView] = [loadingIndicator, titleLabel, descriptionLabel, footerSlotContainer]
    guard !model.presentation.loadingBehavior.hidesImage else {
      imageView.isHidden = true
      customAccessoryContainer.isHidden = true
      return [headerSlotContainer, mediaSlotContainer] + tail
    }

    applyImageVisibility(model: model)
    let imageBlock = imageView
    let customBlock = customAccessoryContainer
    switch customAccessoryPlacement(for: model) {
    case .replaceImage:
      return [headerSlotContainer, mediaSlotContainer, customBlock, contentSlotContainer] + tail
    case .aboveImage:
      return [headerSlotContainer, mediaSlotContainer, customBlock, imageBlock, contentSlotContainer] + tail
    case .belowImage:
      return [headerSlotContainer, mediaSlotContainer, imageBlock, customBlock, contentSlotContainer] + tail
    case .belowDescription:
      return [
        headerSlotContainer,
        mediaSlotContainer,
        imageBlock,
        contentSlotContainer,
        loadingIndicator,
        titleLabel,
        descriptionLabel,
        customBlock,
        footerSlotContainer,
      ]
    }
  }

  // MARK: Empty / error layout

  private func applyContentPhase(model: FKEmptyStateConfiguration, resolved: FKEmptyStateResolvedLayout) {
    loadingIndicator.stopAnimating()

    titleLabel.text = model.content.title
    titleLabel.isHidden = model.content.title?.isEmpty != false

    descriptionLabel.text = model.content.description
    descriptionLabel.isHidden = model.content.description?.isEmpty != false

    applyImageVisibility(model: model)

    applyActions(model: model)

    if model.layout.axis == .horizontal {
      rebuildStack(orderedViews: horizontalContentBlocks(model: model, resolved: resolved))
    } else {
      rebuildStack(orderedViews: contentBlocks(model: model))
    }
  }

  /// Builds stack order for horizontal axis (illustration beside title/description).
  private func horizontalContentBlocks(model: FKEmptyStateConfiguration, resolved: FKEmptyStateResolvedLayout) -> [UIView] {
    prepareHorizontalRow(model: model, resolved: resolved)
    var blocks: [UIView] = [headerSlotContainer, mediaSlotContainer]

    if customAccessoryPlacement(for: model) == .aboveImage, !customAccessoryContainer.isHidden {
      blocks.append(customAccessoryContainer)
    }

    blocks.append(horizontalRowStack)

    switch customAccessoryPlacement(for: model) {
    case .belowImage, .belowDescription:
      if !customAccessoryContainer.isHidden {
        blocks.append(customAccessoryContainer)
      }
    case .replaceImage, .aboveImage:
      break
    }

    blocks.append(contentsOf: [
      contentSlotContainer,
      actionsSlotContainer,
      actionsStack,
      footerSlotContainer,
    ])
    return blocks
  }

  private func prepareHorizontalRow(model: FKEmptyStateConfiguration, resolved: FKEmptyStateResolvedLayout) {
    detachLabelsFromHorizontalRow()

    let metrics = FKEmptyStateLayoutMetrics(density: model.layout.density)
    horizontalTextStack.spacing = metrics.spacing(from: resolved.verticalSpacing)
    horizontalTextStack.addArrangedSubview(titleLabel)
    horizontalTextStack.addArrangedSubview(descriptionLabel)

    horizontalRowStack.arrangedSubviews.forEach {
      horizontalRowStack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    horizontalRowStack.axis = .horizontal
    horizontalRowStack.alignment = .center
    horizontalRowStack.spacing = metrics.horizontalRowSpacing(from: 16)
    horizontalRowStack.isHidden = false

    let textAlignment = model.appearance.typography.textAlignment
    titleLabel.textAlignment = textAlignment == .center ? .natural : textAlignment
    descriptionLabel.textAlignment = textAlignment == .center ? .natural : textAlignment
    horizontalTextStack.alignment = textAlignment == .center ? .center : .leading

    let illustration: UIView? = {
      switch customAccessoryPlacement(for: model) {
      case .replaceImage where !customAccessoryContainer.isHidden:
        return customAccessoryContainer
      default:
        return imageView.isHidden ? nil : imageView
      }
    }()
    if let illustration {
      horizontalRowStack.addArrangedSubview(illustration)
    }
    horizontalRowStack.addArrangedSubview(horizontalTextStack)
  }

  private func detachLabelsFromHorizontalRow() {
    horizontalTextStack.arrangedSubviews.forEach {
      horizontalTextStack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
  }

  private func applyImagePresentation(model: FKEmptyStateConfiguration) {
    guard let imageContent = model.content.image else {
      imageView.image = nil
      imageView.tintColor = nil
      return
    }
    imageView.contentMode = imageContent.contentMode
    if let tint = imageContent.tintColor {
      imageView.tintColor = tint
      imageView.image = imageContent.image.withRenderingMode(.alwaysTemplate)
    } else {
      imageView.tintColor = nil
      imageView.image = imageContent.image
    }
  }

  private func customAccessoryPlacement(for model: FKEmptyStateConfiguration) -> FKEmptyStateCustomPlacement {
    model.content.customAccessory?.placement ?? .belowImage
  }

  private func customAccessoryView(for model: FKEmptyStateConfiguration) -> UIView? {
    model.content.customAccessory?.view
  }

  /// Builds stack order for empty/error based on custom accessory placement.
  private func contentBlocks(model: FKEmptyStateConfiguration) -> [UIView] {
    detachLabelsFromHorizontalRow()
    horizontalRowStack.isHidden = true
    let imageBlock = imageView
    let customBlock = customAccessoryContainer
    switch customAccessoryPlacement(for: model) {
    case .replaceImage:
      return [
        headerSlotContainer,
        mediaSlotContainer,
        customBlock,
        contentSlotContainer,
        titleLabel,
        descriptionLabel,
        actionsSlotContainer,
        actionsStack,
        footerSlotContainer,
      ]
    case .aboveImage:
      return [
        headerSlotContainer,
        mediaSlotContainer,
        customBlock,
        imageBlock,
        contentSlotContainer,
        titleLabel,
        descriptionLabel,
        actionsSlotContainer,
        actionsStack,
        footerSlotContainer,
      ]
    case .belowImage:
      return [
        headerSlotContainer,
        mediaSlotContainer,
        imageBlock,
        customBlock,
        contentSlotContainer,
        titleLabel,
        descriptionLabel,
        actionsSlotContainer,
        actionsStack,
        footerSlotContainer,
      ]
    case .belowDescription:
      return [
        headerSlotContainer,
        mediaSlotContainer,
        imageBlock,
        contentSlotContainer,
        titleLabel,
        descriptionLabel,
        customBlock,
        actionsSlotContainer,
        actionsStack,
        footerSlotContainer,
      ]
    }
  }

  private func rebuildStack(orderedViews: [UIView]) {
    stackView.arrangedSubviews.forEach {
      stackView.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    for v in orderedViews {
      if v === headerSlotContainer || v === mediaSlotContainer || v === contentSlotContainer || v === actionsSlotContainer || v === footerSlotContainer {
        v.isHidden = v.subviews.isEmpty
      }
      if v === actionsStack {
        v.isHidden = actionsStack.arrangedSubviews.isEmpty || actionsStack.isHidden
      }
      stackView.addArrangedSubview(v)
    }
  }

  private func syncCustomAccessoryIfNeeded(model: FKEmptyStateConfiguration) {
    if customAccessoryView(for: model) == nil {
      setCustomAccessoryView(nil)
      return
    }
    if let provided = customAccessoryView(for: model), provided.superview !== customAccessoryContainer {
      setCustomAccessoryView(provided)
    }
  }

  private func applyImageConstraints(imageSize: CGSize?) {
    if let imageSize {
      if imageWidthConstraint == nil {
        imageWidthConstraint = imageView.widthAnchor.constraint(equalToConstant: imageSize.width)
      }
      if imageHeightConstraint == nil {
        imageHeightConstraint = imageView.heightAnchor.constraint(equalToConstant: imageSize.height)
      }
      imageWidthConstraint?.constant = imageSize.width
      imageHeightConstraint?.constant = imageSize.height
      imageWidthConstraint?.isActive = true
      imageHeightConstraint?.isActive = true
    } else {
      imageWidthConstraint?.isActive = false
      imageHeightConstraint?.isActive = false
    }
  }

  private func updateGradient(with model: FKEmptyStateConfiguration) {
    let background = model.appearance.background
    guard !background.gradientColors.isEmpty else {
      gradientLayer?.removeFromSuperlayer()
      gradientLayer = nil
      return
    }
    let layer = gradientLayer ?? CAGradientLayer()
    layer.colors = background.gradientColors.map(\.cgColor)
    layer.startPoint = background.gradientStartPoint
    layer.endPoint = background.gradientEndPoint
    layer.frame = bounds
    if layer.superlayer == nil {
      self.layer.insertSublayer(layer, at: 0)
    }
    gradientLayer = layer
  }

  /// Clears prior button titles, attributed titles, and `UIButton.Configuration` before applying new chrome.
  private func resetButtonPresentation(_ button: UIButton) {
    button.configuration = nil
    for state: UIControl.State in [.normal, .highlighted, .disabled, .selected, .focused] {
      button.setTitle(nil, for: state)
      button.setAttributedTitle(nil, for: state)
    }
    button.backgroundColor = .clear
    button.layer.borderWidth = 0
    button.layer.cornerRadius = 0
    button.contentEdgeInsets = .zero
  }

  /// Applies ``FKEmptyStateButtonStyle/font`` through `UIButton.Configuration` (setting `titleLabel?.font` is ignored on iOS 15+).
  private func applyConfigurationTypography(_ style: FKEmptyStateButtonStyle, to configuration: inout UIButton.Configuration) {
    let font = style.font
    configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = font
      return outgoing
    }
  }

  /// Applies corner radius and optional border through configuration background (layer properties do not affect configuration chrome).
  private func applyConfigurationChrome(_ style: FKEmptyStateButtonStyle, to configuration: inout UIButton.Configuration) {
    switch style.cornerStyle {
    case .capsule:
      configuration.cornerStyle = .capsule
    case .fixed(let radius):
      configuration.cornerStyle = .fixed
      configuration.background.cornerRadius = radius
    }
    if style.borderWidth > 0, let borderColor = style.borderColor {
      configuration.background.strokeColor = borderColor
      configuration.background.strokeWidth = style.borderWidth
    }
  }

  private func applyLinkButtonStyle(
    style: FKEmptyStateButtonStyle,
    button: UIButton,
    title: String?,
    isEnabled: Bool
  ) {
    resetButtonPresentation(button)
    let linkColor = style.titleColor
    let font = style.font
    button.contentEdgeInsets = style.contentInsets
    guard let title else {
      button.isEnabled = isEnabled
      return
    }
    let normalAttributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: linkColor,
      .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]
    let disabledColor = linkColor.withAlphaComponent(0.35)
    let disabledAttributes: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: disabledColor,
      .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]
    button.setAttributedTitle(NSAttributedString(string: title, attributes: normalAttributes), for: .normal)
    button.setAttributedTitle(NSAttributedString(string: title, attributes: normalAttributes), for: .highlighted)
    button.setAttributedTitle(NSAttributedString(string: title, attributes: normalAttributes), for: .selected)
    button.setAttributedTitle(NSAttributedString(string: title, attributes: disabledAttributes), for: .disabled)
    button.isEnabled = isEnabled
  }

  private func applyImageVisibility(model: FKEmptyStateConfiguration) {
    let imageHiddenFlag = model.content.image == nil
    let customMissing = customAccessoryView(for: model) == nil && customAccessoryContainer.subviews.isEmpty
    switch customAccessoryPlacement(for: model) {
    case .replaceImage:
      imageView.isHidden = true
      customAccessoryContainer.isHidden = customMissing
    default:
      imageView.isHidden = imageHiddenFlag
      customAccessoryContainer.isHidden = customMissing
    }
  }

  private func applyButtonLoadingState(_ button: UIButton, action: FKEmptyStateAction) {
    button.isEnabled = action.isEnabled && !action.isLoading
    guard var config = button.configuration else { return }
    config.showsActivityIndicator = action.isLoading
    if action.isLoading {
      config.title = action.title
    }
    button.configuration = config
  }

  private func applyActionStyle(
    model: FKEmptyStateConfiguration,
    button: UIButton,
    action: FKEmptyStateAction
  ) {
    if action.kind == .link {
      let linkStyle = model.appearance.buttons.resolvedTertiary()
      if action.isLoading {
        var config = UIButton.Configuration.plain()
        config.title = action.title
        config.baseForegroundColor = linkStyle.titleColor
        config.showsActivityIndicator = true
        applyConfigurationTypography(linkStyle, to: &config)
        button.configuration = config
        button.setAttributedTitle(nil, for: .normal)
      } else {
        applyLinkButtonStyle(
          style: linkStyle,
          button: button,
          title: action.title,
          isEnabled: action.isEnabled && !action.isLoading
        )
      }
      button.isEnabled = action.isEnabled && !action.isLoading
      return
    }

    switch action.kind {
    case .primary:
      applyPrimaryButtonStyle(style: model.appearance.buttons.primary, title: action.title, button: button)
    case .secondary:
      applySecondaryButtonStyle(style: model.appearance.buttons.resolvedSecondary(), title: action.title, button: button)
    case .tertiary:
      applyTertiaryButtonStyle(style: model.appearance.buttons.resolvedTertiary(), title: action.title, button: button)
    case .link:
      break
    }
    applyButtonLoadingState(button, action: action)
  }

  /// Applies filled primary button styling using `UIButton.Configuration`.
  private func applyPrimaryButtonStyle(style: FKEmptyStateButtonStyle, title: String?, button: UIButton) {
    resetButtonPresentation(button)
    var buttonConfig = UIButton.Configuration.filled()
    buttonConfig.title = title
    buttonConfig.baseBackgroundColor = style.backgroundColor
    buttonConfig.baseForegroundColor = style.titleColor
    buttonConfig.contentInsets = NSDirectionalEdgeInsets(
      top: style.contentInsets.top,
      leading: style.contentInsets.left,
      bottom: style.contentInsets.bottom,
      trailing: style.contentInsets.right
    )
    applyConfigurationTypography(style, to: &buttonConfig)
    applyConfigurationChrome(style, to: &buttonConfig)
    button.configuration = buttonConfig
    button.setTitle(nil, for: .normal)
  }

  private func applySecondaryButtonStyle(style: FKEmptyStateButtonStyle, title: String?, button: UIButton) {
    resetButtonPresentation(button)
    var cfg = UIButton.Configuration.bordered()
    cfg.title = title
    cfg.baseForegroundColor = style.titleColor
    cfg.contentInsets = NSDirectionalEdgeInsets(
      top: style.contentInsets.top,
      leading: style.contentInsets.left,
      bottom: style.contentInsets.bottom,
      trailing: style.contentInsets.right
    )
    applyConfigurationTypography(style, to: &cfg)
    applyConfigurationChrome(style, to: &cfg)
    button.configuration = cfg
    button.setTitle(nil, for: .normal)
  }

  private func applyTertiaryButtonStyle(style: FKEmptyStateButtonStyle, title: String?, button: UIButton) {
    resetButtonPresentation(button)
    var cfg = UIButton.Configuration.plain()
    cfg.title = title
    cfg.baseForegroundColor = style.titleColor
    cfg.contentInsets = NSDirectionalEdgeInsets(
      top: style.contentInsets.top,
      leading: style.contentInsets.left,
      bottom: style.contentInsets.bottom,
      trailing: style.contentInsets.right
    )
    applyConfigurationTypography(style, to: &cfg)
    applyConfigurationChrome(style, to: &cfg)
    if style.backgroundColor != .clear {
      cfg.background.backgroundColor = style.backgroundColor
    }
    button.configuration = cfg
  }

  /// Injects a default retry action for ``FKEmptyStatePhase/error`` when none is configured.
  private func resolvedActions(for model: FKEmptyStateConfiguration) -> FKEmptyStateActionSet {
    var actions = model.actions
    if model.phase == .error,
       actions.primary == nil || actions.primary?.title.isEmpty == true {
      actions.primary = FKEmptyStateAction(
        id: "retry",
        title: FKEmptyStateConfiguration.defaultRetryButtonTitle,
        kind: .primary
      )
    }
    return actions
  }

  private func applyActions(model: FKEmptyStateConfiguration) {
    actionsStack.arrangedSubviews.forEach {
      actionsStack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }

    let actions = resolvedActions(for: model)

    if let p = actions.primary {
      applyActionStyle(model: model, button: primaryButton, action: p)
      actionsStack.addArrangedSubview(primaryButton)
    }
    if let s = actions.secondary {
      applyActionStyle(model: model, button: secondaryButton, action: s)
      actionsStack.addArrangedSubview(secondaryButton)
    }
    if let t = actions.tertiary {
      applyActionStyle(model: model, button: tertiaryButton, action: t)
      actionsStack.addArrangedSubview(tertiaryButton)
    }

    actionsStack.isHidden = actionsStack.arrangedSubviews.isEmpty
  }

  private func applySlots(model: FKEmptyStateConfiguration) {
    replaceSlot(in: headerSlotContainer, with: model.slots.header)
    replaceSlot(in: mediaSlotContainer, with: model.slots.media)
    replaceSlot(in: contentSlotContainer, with: model.slots.content)
    replaceSlot(in: actionsSlotContainer, with: model.slots.actions)
    replaceSlot(in: footerSlotContainer, with: model.slots.footer)
  }

  /// Updates slot container visibility after slot content is applied (`rebuildStack` runs earlier with empty slots).
  private func refreshSlotContainerVisibility() {
    for container in [
      headerSlotContainer,
      mediaSlotContainer,
      contentSlotContainer,
      actionsSlotContainer,
      footerSlotContainer,
    ] {
      container.isHidden = container.subviews.isEmpty
    }
  }

  /// Applies per-segment stack spacing; explicit values skip density scaling (see ``FKEmptyStateSpacingConfiguration``).
  private func applySegmentSpacing(model: FKEmptyStateConfiguration, resolved: FKEmptyStateResolvedLayout) {
    let metrics = FKEmptyStateLayoutMetrics(density: model.layout.density)
    let fallback = resolved.verticalSpacing
    let segments = model.layout.segmentSpacing

    func spacing(_ explicit: CGFloat?) -> CGFloat {
      metrics.segmentSpacing(explicit, fallback: fallback)
    }

    if model.layout.axis == .horizontal {
      if !titleLabel.isHidden {
        horizontalTextStack.setCustomSpacing(spacing(segments.afterTitle), after: titleLabel)
      }
      if !descriptionLabel.isHidden {
        horizontalTextStack.setCustomSpacing(spacing(segments.afterDescription), after: descriptionLabel)
      }
      if !horizontalRowStack.isHidden, stackView.arrangedSubviews.contains(horizontalRowStack) {
        stackView.setCustomSpacing(spacing(segments.afterImage), after: horizontalRowStack)
      }
    } else {
      if let imageAnchor = imageSpacingAnchor() {
        stackView.setCustomSpacing(spacing(segments.afterImage), after: imageAnchor)
      }
      if !titleLabel.isHidden, stackView.arrangedSubviews.contains(titleLabel) {
        stackView.setCustomSpacing(spacing(segments.afterTitle), after: titleLabel)
      }
      if !descriptionLabel.isHidden, stackView.arrangedSubviews.contains(descriptionLabel) {
        stackView.setCustomSpacing(spacing(segments.afterDescription), after: descriptionLabel)
      }
    }

    if !actionsSlotContainer.isHidden, stackView.arrangedSubviews.contains(actionsSlotContainer) {
      stackView.setCustomSpacing(spacing(segments.afterActionsSlot), after: actionsSlotContainer)
    }
  }

  /// Last visible arranged subview before the title block; used for ``FKEmptyStateSpacingConfiguration/afterImage``.
  private func imageSpacingAnchor() -> UIView? {
    let arranged = stackView.arrangedSubviews
    guard let titleIndex = arranged.firstIndex(where: { $0 === titleLabel }) else { return nil }
    guard titleIndex > 0 else { return nil }
    for index in stride(from: titleIndex - 1, through: 0, by: -1) {
      let candidate = arranged[index]
      if !candidate.isHidden { return candidate }
    }
    return nil
  }

  private func replaceSlot(in container: UIView, with view: UIView?) {
    container.subviews.forEach { $0.removeFromSuperview() }
    guard let view else { return }
    view.translatesAutoresizingMaskIntoConstraints = false
    container.addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: container.topAnchor),
      view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])
  }

  private func applyAccessibility(model: FKEmptyStateConfiguration) {
    isAccessibilityElement = false
    accessibilityViewIsModal = false

    if let label = model.content.image?.accessibilityLabel, !label.isEmpty, !imageView.isHidden {
      imageView.isAccessibilityElement = true
      imageView.accessibilityLabel = label
      imageView.accessibilityTraits = .image
    } else {
      imageView.isAccessibilityElement = false
      imageView.accessibilityLabel = nil
    }
  }

  private func announcementSignature(model: FKEmptyStateConfiguration) -> String {
    let (primary, secondary) = announcementLines(for: model)
    return "\(model.phase)|\(model.type.rawValue)|\(primary)|\(secondary)"
  }

  /// Lines VoiceOver should speak, aligned with `applyLoadingPhase` / `applyContentPhase` labels.
  private func announcementLines(for model: FKEmptyStateConfiguration) -> (primary: String, secondary: String) {
    switch model.phase {
    case .loading:
      let primary = (model.content.loadingMessage ?? model.content.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let showDesc = !model.presentation.loadingBehavior.hidesDescription && !(model.content.description?.isEmpty ?? true)
      let secondary: String
      if showDesc, let d = model.content.description {
        secondary = d.trimmingCharacters(in: .whitespacesAndNewlines)
      } else {
        secondary = ""
      }
      return (primary, secondary)
    case .content:
      return ("", "")
    case .empty, .error, .custom:
      let primary = (model.content.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      let secondary = (model.content.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
      return (primary, secondary)
    }
  }

  private func announceIfNeeded(model: FKEmptyStateConfiguration) {
    guard model.presentation.announcesStateChanges else { return }
    guard !isHidden, alpha > 0.01 else { return }
    guard UIAccessibility.isVoiceOverRunning else { return }
    guard model.phase != .content else { return }

    let sig = announcementSignature(model: model)
    if sig == lastAnnouncementSignature { return }
    lastAnnouncementSignature = sig

    let lines = announcementLines(for: model)
    let message = [lines.primary, lines.secondary]
      .filter { !$0.isEmpty }
      .joined(separator: ", ")
    guard !message.isEmpty else { return }
    // We use `.announcement` (not `.screenChanged`) to avoid interrupting navigation context
    // for users who keep exploring the underlying screen while the overlay appears.
    UIAccessibility.post(notification: .announcement, argument: message)
  }

  /// Updates container constraints according to alignment and offset preferences.
  private func updateContentPosition(resolved: FKEmptyStateResolvedLayout, model: FKEmptyStateConfiguration) {
    switch resolved.contentAlignment {
    case .center:
      updateScrollViewportAnchoring()
      activeCenterYConstraint()?.constant = model.layout.verticalOffset
      containerTopConstraint?.isActive = false
    case .top:
      containerCenterYToSafeAreaConstraint?.isActive = false
      containerCenterYToBoundsConstraint?.isActive = false
      containerTopConstraint?.isActive = true
      containerTopConstraint?.constant = model.layout.verticalOffset
    }
  }

  /// On `UIScrollView` hosts, anchor to bounds center so `contentInset` changes during pull-to-refresh
  /// do not shift the overlay via `safeAreaLayoutGuide`.
  private func updateScrollViewportAnchoring() {
    let usesViewportCenter = superview is UIScrollView
    containerCenterYToSafeAreaConstraint?.isActive = !usesViewportCenter
    containerCenterXToSafeAreaConstraint?.isActive = !usesViewportCenter
    containerCenterYToBoundsConstraint?.isActive = usesViewportCenter
    containerCenterXToBoundsConstraint?.isActive = usesViewportCenter
  }

  private func activeCenterYConstraint() -> NSLayoutConstraint? {
    superview is UIScrollView
      ? containerCenterYToBoundsConstraint
      : containerCenterYToSafeAreaConstraint
  }

  // MARK: UIGestureRecognizerDelegate

  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    // Walk up the hierarchy instead of checking only `touch.view`.
    // Some button internals report label/image subviews as the touched view; without this
    // ancestor check, background tap handlers may fire when users interact near CTA content.
    var current: UIView? = touch.view
    while let view = current {
      if view is UIControl { return false }
      current = view.superview
    }
    return true
  }

  // MARK: Actions

  @objc private func handlePrimaryTap() {
    guard let action = resolvedActions(for: configuration).primary else { return }
    emitAction(action)
  }

  @objc private func handleSecondaryTap() {
    let action = resolvedActions(for: configuration).secondary
      ?? FKEmptyStateAction(id: "secondary", title: "", kind: .secondary)
    emitAction(action)
  }

  @objc private func handleTertiaryTap() {
    let action = resolvedActions(for: configuration).tertiary
      ?? FKEmptyStateAction(id: "tertiary", title: "", kind: .tertiary)
    emitAction(action)
  }

  private func emitAction(_ action: FKEmptyStateAction) {
    actionHandler?(action)
    delegate?.emptyStateView(self, didTap: action)
    NotificationCenter.default.post(
      name: .fk_emptyStateActionInvoked,
      object: self,
      userInfo: [
        FKEmptyStateNotificationKeys.id: action.id,
        FKEmptyStateNotificationKeys.kind: action.kind.rawValue,
        FKEmptyStateNotificationKeys.title: action.title,
        FKEmptyStateNotificationKeys.payload: action.payload
      ]
    )
  }

  @objc private func handleBackgroundTap() {
    if configuration.presentation.supportsTapToDismissKeyboard {
      endEditing(true)
    }
    viewTapHandler?()
  }
}

public extension Notification.Name {
  static let fk_emptyStateActionInvoked = Notification.Name("fk.emptyState.actionInvoked")
}

/// Keys used by the `.fk_emptyStateActionInvoked` notification userInfo payload.
///
/// This is a lightweight interop channel for hosts that prefer NotificationCenter routing
/// (e.g. multiple actions handled by a coordinator without wiring closures).
public enum FKEmptyStateNotificationKeys {
  public static let id = "id"
  public static let kind = "kind"
  /// Button (or action) title at tap time; mirrors ``FKEmptyStateAction/title``.
  public static let title = "title"
  public static let payload = "payload"
}
