import FKCoreKit
import UIKit

/// Presentation mode for avatar content.
enum FKAvatarContentMode: Equatable {
  case empty
  case loading
  case image
  case initials
  case placeholder
  case failed
}

/// Configuration-driven single-user avatar with initials fallback, URL loading, and optional presence.
///
/// Use ``resetForReuse()`` from cell `prepareForReuse()` to cancel in-flight loads. Attach badges via ``FKBadgeController``.
@MainActor
public final class FKAvatar: UIControl {
  /// Baseline copied by ``init(frame:)`` until replaced via ``configuration``.
  public static var defaultConfiguration: FKAvatarConfiguration {
    get { FKAvatarDefaults.configuration }
    set { FKAvatarDefaults.configuration = newValue }
  }

  /// Layered layout, appearance, interaction, accessibility, and presence settings.
  public var configuration: FKAvatarConfiguration = FKAvatar.defaultConfiguration {
    didSet {
      guard !isApplyingNestedConfigurationUpdate else { return }
      applyConfiguration()
    }
  }

  /// Display name for initials fallback and VoiceOver.
  public var displayName: String? {
    didSet {
      guard oldValue != displayName else { return }
      refreshContentPresentation()
      updateAccessibility()
    }
  }

  /// Remote image URL bound to the embedded ``FKImageView``.
  public var imageURL: URL? {
    get { imageView?.url }
    set {
      guard imageURL != newValue else { return }
      setImageURL(newValue, placeholder: nil)
    }
  }

  /// Local bitmap; takes precedence over ``imageURL`` when set.
  public var image: UIImage? {
    get { storedImage }
    set {
      guard storedImage != newValue else { return }
      storedImage = newValue
      refreshContentPresentation()
    }
  }

  // MARK: - Subviews

  let contentContainer = UIView()
  var imageView: FKImageView?
  var initialsLabel: UILabel?
  var placeholderImageView: UIImageView?
  var skeletonView: FKSkeletonView?
  var verifiedBadgeView: UIImageView?
  var presenceIndicator: FKPresenceIndicator?

  // MARK: - Private state

  var storedImage: UIImage?
  var presentationMode: FKAvatarContentMode = .empty
  private var storyRingLayer: FKAvatarStoryRingLayer?
  private var isApplyingNestedConfigurationUpdate = false

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Creates an avatar with explicit configuration.
  public convenience init(configuration: FKAvatarConfiguration) {
    self.init(frame: .zero)
    self.configuration = configuration
  }

  public override var intrinsicContentSize: CGSize {
    let diameter = configuration.layout.size.diameter
    let ringExtra = storyRingExtraInset * 2
    return CGSize(width: diameter + ringExtra, height: diameter + ringExtra)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    layoutContent()
  }

  public override var isHighlighted: Bool {
    didSet {
      guard oldValue != isHighlighted else { return }
      applyHighlightFeedback()
    }
  }

  public override var isUserInteractionEnabled: Bool {
    didSet {
      guard oldValue != isUserInteractionEnabled else { return }
      updateAccessibility()
    }
  }

  public override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    guard configuration.interaction.expandsHitAreaToMinimumSize else {
      return super.point(inside: point, with: event)
    }
    let minSize = configuration.interaction.minimumHitAreaSize
    let w = max(bounds.width, minSize.width)
    let h = max(bounds.height, minSize.height)
    let hit = CGRect(x: bounds.midX - w / 2, y: bounds.midY - h / 2, width: w, height: h)
    return hit.contains(point)
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
      setNeedsLayout()
    }
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      refreshInitialsTypographyIfNeeded()
    }
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      applyAppearance()
      if presentationMode == .placeholder || presentationMode == .failed {
        updateVisibleLayers()
      }
    }
  }

  // MARK: - Public API

  /// Runtime presence state; assign without replacing the full ``configuration`` snapshot.
  ///
  /// Requires ``FKAvatarConfiguration/showsPresenceIndicator`` to be `true` for the dot to appear.
  public var presenceState: FKPresenceState? {
    get { configuration.presenceState }
    set {
      guard configuration.presenceState != newValue else { return }
      isApplyingNestedConfigurationUpdate = true
      configuration.presenceState = newValue
      isApplyingNestedConfigurationUpdate = false
      applyPresence()
      updateAccessibility()
    }
  }

  /// Toggles the attached presence indicator without rebuilding other configuration groups.
  public var showsPresenceIndicator: Bool {
    get { configuration.showsPresenceIndicator }
    set {
      guard configuration.showsPresenceIndicator != newValue else { return }
      isApplyingNestedConfigurationUpdate = true
      configuration.showsPresenceIndicator = newValue
      isApplyingNestedConfigurationUpdate = false
      applyPresence()
      updateAccessibility()
    }
  }

  /// Sets a remote URL with an optional placeholder bitmap.
  public func setImageURL(_ url: URL?, placeholder: UIImage?) {
    storedImage = nil
    if url != nil || imageView != nil {
      ensureImageView().load(url: url, placeholder: placeholder)
      refreshContentPresentation(forceURLBind: true)
    } else {
      refreshContentPresentation()
    }
  }

  /// Updates the display name and refreshes initials fallback.
  public func setDisplayName(_ name: String?) {
    displayName = name
  }

  /// Cell-reuse helper: cancels loads and clears transient state without changing configuration.
  ///
  /// Retains an attached ``FKImageView`` so URL-heavy list cells avoid recreate churn on the next bind.
  public func resetForReuse() {
    storedImage = nil
    displayName = nil
    imageView?.resetForReuse()
    presentationMode = .empty
    updateVisibleLayers()
    updateAccessibility()
  }

  // MARK: - Setup

  private func commonInit() {
    isAccessibilityElement = true
    accessibilityTraits = .image
    clipsToBounds = false
    backgroundColor = .clear
    setContentHuggingPriority(.required, for: .horizontal)
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .vertical)

    contentContainer.isUserInteractionEnabled = false

    addSubview(contentContainer)

    applyConfiguration()
    refreshContentPresentation()
  }

  private func applyConfiguration() {
    configureImageView()
    applyAppearance()
    applyPresence()
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    refreshContentPresentation()
    updateAccessibility()
  }

  func configureImageView() {
    guard let imageView else { return }
    var imageConfiguration = FKImageViewConfiguration.profile(.listCell)
    imageConfiguration.appearance.cornerStyle = FKAvatarContentRenderer.imageViewCornerStyle(
      shape: configuration.layout.shape,
      diameter: configuration.layout.size.diameter
    )
    imageConfiguration.appearance.contentMode = .scaleAspectFill
    imageConfiguration.appearance.borderStyle = .none
    imageConfiguration.appearance.successTransition = .fadeIn(duration: 0.15)
    imageConfiguration.loading.loadingPresentation = .init(
      progressMode: .none,
      includesSkeleton: false
    )
    imageConfiguration.failure.showsFailureOverlay = false
    imageConfiguration.failure.isRetryEnabled = configuration.interaction.retriesOnFailure
    imageView.configuration = imageConfiguration
  }

  private func applyAppearance() {
    contentContainer.layer.fk_applyBorder(configuration.appearance.borderStyle)
    if configuration.appearance.showsVerifiedBadge {
      let badge = ensureVerifiedBadgeView()
      badge.tintColor = configuration.appearance.verifiedBadgeTintColor
      badge.image = FKAvatarContentRenderer.verifiedBadgeImage(
        symbolName: configuration.appearance.verifiedBadgeSymbolName,
        diameter: configuration.layout.size.diameter
      )
    } else {
      releaseVerifiedBadgeView()
    }

    if let story = configuration.appearance.storyRing {
      ensureStoryRingLayer()
      storyRingLayer?.ringWidth = story.width
      storyRingLayer?.ringPadding = story.padding
      storyRingLayer?.gradientColors = story.gradientColors
      storyRingLayer?.isHidden = false
    } else {
      storyRingLayer?.isHidden = true
    }
  }

  private func applyPresence() {
    let shows = configuration.showsPresenceIndicator && configuration.presenceState != nil
    if shows, let state = configuration.presenceState {
      let indicator = ensurePresenceIndicator()
      indicator.configuration = configuration.presenceConfiguration
        ?? FKPresenceIndicatorConfiguration(
          size: FKPresenceIndicatorSize.recommended(forAvatarDiameter: configuration.layout.size.diameter)
        )
      indicator.state = state
    } else {
      releasePresenceIndicator()
    }
    setNeedsLayout()
  }

  // MARK: - Content

  private func refreshContentPresentation(forceURLBind: Bool = false) {
    if let storedImage {
      ensureImageView().setImage(storedImage, animated: false)
      transitionContentMode(to: .image)
      return
    }

    if let imageView, imageView.url != nil || forceURLBind {
      switch imageView.state {
      case .loading:
        transitionContentMode(to: .loading)
      case .failure:
        transitionContentMode(to: .failed)
      case .success:
        transitionContentMode(to: .image)
      case .placeholder:
        transitionContentMode(to: .loading)
      case .idle:
        if imageView.url != nil {
          transitionContentMode(to: .loading)
        } else {
          showFallbackContent()
        }
      }
      return
    }

    showFallbackContent()
  }

  private func showFallbackContent() {
    if let name = displayName?.fk_trimmed.fk_removingSpecialCharacters, !name.fk_isBlank {
      let text = FKAvatarInitialsGenerator.initials(from: name)
      if !text.isEmpty {
        applyInitialsPresentation(text: text, displayName: name)
        transitionContentMode(to: .initials)
        return
      }
    }
    transitionContentMode(to: .placeholder)
  }

  private func applyInitialsPresentation(text: String, displayName: String) {
    let label = ensureInitialsLabel()
    label.text = text
    label.font = FKAvatarContentRenderer.initialsFont(
      base: configuration.appearance.initialsFont,
      diameter: configuration.layout.size.diameter
    )
    label.textColor = configuration.appearance.initialsTextColor
    label.backgroundColor = FKAvatarInitialsGenerator.backgroundColor(for: displayName)
  }

  private func refreshInitialsTypographyIfNeeded() {
    guard presentationMode == .initials,
          let name = displayName?.fk_trimmed.fk_removingSpecialCharacters,
          !name.fk_isBlank
    else { return }
    let text = FKAvatarInitialsGenerator.initials(from: name)
    guard !text.isEmpty else { return }
    applyInitialsPresentation(text: text, displayName: name)
  }

  private func transitionContentMode(to mode: FKAvatarContentMode) {
    guard presentationMode != mode else {
      updateVisibleLayers()
      return
    }
    let previous = presentationMode
    presentationMode = mode
    updateVisibleLayers()

    if configuration.accessibility.announcesLoadingStateChanges {
      switch (previous, mode) {
      case (_, .loading):
        UIAccessibility.post(notification: .announcement, argument: FKAvatarI18n.loadingAnnouncement)
      case (_, .failed):
        UIAccessibility.post(notification: .announcement, argument: FKAvatarI18n.loadFailedAnnouncement)
      default:
        break
      }
    }
    updateAccessibility()
  }

  func handleImageViewStateChange(_ state: FKImageViewState) {
    guard storedImage == nil else { return }
    switch state {
    case .loading, .placeholder:
      transitionContentMode(to: .loading)
    case .failure:
      transitionContentMode(to: .failed)
    case .success:
      transitionContentMode(to: .image)
    case .idle:
      if imageView?.url == nil {
        showFallbackContent()
      }
    }
  }

  private func updateVisibleLayers() {
    syncImageViewAttachment()
    imageView?.isHidden = presentationMode != .image && presentationMode != .loading && presentationMode != .failed
    syncLazyPresentationSubviews()

    if presentationMode == .placeholder || presentationMode == .failed {
      if presentationMode == .failed {
        contentContainer.backgroundColor = .secondarySystemFill
      } else {
        contentContainer.backgroundColor = .tertiarySystemFill
      }
    } else if presentationMode != .initials {
      contentContainer.backgroundColor = .clear
    }
  }

  // MARK: - Layout

  private var storyRingExtraInset: CGFloat {
    guard let story = configuration.appearance.storyRing, storyRingLayer?.isHidden == false else { return 0 }
    return story.width + story.padding
  }

  private func layoutContent() {
    let diameter = configuration.layout.size.diameter
    let inset = storyRingExtraInset
    contentContainer.frame = CGRect(
      x: inset,
      y: inset,
      width: diameter,
      height: diameter
    )

    FKAvatarContentRenderer.applyShape(
      to: contentContainer,
      shape: configuration.layout.shape,
      diameter: diameter
    )
    if let initialsLabel {
      FKAvatarContentRenderer.applyShape(
        to: initialsLabel,
        shape: configuration.layout.shape,
        diameter: diameter
      )
      initialsLabel.frame = contentContainer.bounds
    }
    if let skeletonView {
      FKAvatarContentRenderer.applyShape(
        to: skeletonView,
        shape: configuration.layout.shape,
        diameter: diameter
      )
      skeletonView.frame = contentContainer.bounds
    }

    if let imageView {
      imageView.frame = contentContainer.bounds
    }
    if let placeholderImageView {
      placeholderImageView.frame = contentContainer.bounds.insetBy(dx: diameter * 0.22, dy: diameter * 0.22)
    }

    storyRingLayer?.frame = bounds

    if configuration.appearance.showsVerifiedBadge, let verifiedBadgeView {
      let badgeSize = diameter * 0.32
      let isRTL = traitCollection.layoutDirection == .rightToLeft
      let x: CGFloat
      if isRTL {
        x = contentContainer.frame.minX - badgeSize * 0.25
      } else {
        x = contentContainer.frame.maxX - badgeSize * 0.75
      }
      verifiedBadgeView.frame = CGRect(
        x: x,
        y: contentContainer.frame.maxY - badgeSize * 0.75,
        width: badgeSize,
        height: badgeSize
      )
    }

    layoutPresenceIndicator(diameter: diameter, contentFrame: contentContainer.frame)
  }

  private func layoutPresenceIndicator(diameter: CGFloat, contentFrame: CGRect) {
    guard let presenceIndicator else { return }
    let indicatorDiameter = presenceIndicator.configuration.size.diameter
    let borderOutset = presenceIndicator.configuration.showsBorder
      ? presenceIndicator.configuration.borderWidth
      : 0
    let totalIndicator = indicatorDiameter + borderOutset * 2
    let isRTL = traitCollection.layoutDirection == .rightToLeft
    let offset = FKWidgetLayoutMetrics.presenceIndicatorOffset(
      avatarDiameter: diameter,
      indicatorDiameter: totalIndicator,
      isRTL: isRTL
    )

    let originX: CGFloat
    let originY = contentFrame.maxY - totalIndicator + offset.vertical
    if isRTL {
      originX = contentFrame.minX - offset.horizontal - totalIndicator
    } else {
      originX = contentFrame.maxX - totalIndicator + offset.horizontal
    }
    presenceIndicator.frame = CGRect(x: originX, y: originY, width: totalIndicator, height: totalIndicator)
  }

  private func ensureStoryRingLayer() {
    guard storyRingLayer == nil else { return }
    let ringLayer = FKAvatarStoryRingLayer()
    layer.insertSublayer(ringLayer, at: 0)
    storyRingLayer = ringLayer
  }

  // MARK: - Interaction

  private func applyHighlightFeedback() {
    guard configuration.interaction.highlightsOnPress else { return }
    let reduceMotion = UIAccessibility.isReduceMotionEnabled
    let scale = isHighlighted ? configuration.interaction.highlightScale : 1
    let animations = {
      self.contentContainer.transform = reduceMotion ? .identity : CGAffineTransform(scaleX: scale, y: scale)
    }
    if reduceMotion {
      animations()
      return
    }
    let duration: TimeInterval = isHighlighted ? 0.08 : 0.15
    UIView.animate(
      withDuration: duration,
      delay: 0,
      options: [.beginFromCurrentState, .allowUserInteraction],
      animations: animations
    )
  }

  public override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    super.endTracking(touch, with: event)
    if presentationMode == .failed, configuration.interaction.retriesOnFailure {
      imageView?.retry()
    }
  }

  // MARK: - Accessibility

  private func updateAccessibility() {
    if isEnabled, isUserInteractionEnabled {
      accessibilityTraits = [.image, .button]
    } else {
      accessibilityTraits = .image
    }

    if let custom = configuration.accessibility.customLabel {
      accessibilityLabel = custom
    } else if let name = displayName?.fk_trimmed, !name.isEmpty {
      accessibilityLabel = FKAvatarI18n.avatarLabel(for: name)
    } else {
      accessibilityLabel = FKAvatarI18n.defaultAvatarLabel
    }

    var hints: [String] = []
    if let hint = configuration.accessibility.hint {
      hints.append(hint)
    }
    if configuration.appearance.showsVerifiedBadge {
      hints.append(FKAvatarI18n.verifiedBadgeHint)
    }
    if configuration.showsPresenceIndicator, let state = configuration.presenceState {
      hints.append(state.accessibilityLabel)
    }

    switch presentationMode {
    case .loading:
      accessibilityValue = FKAvatarI18n.loadingAnnouncement
    case .failed:
      accessibilityValue = FKAvatarI18n.loadFailedAnnouncement
      if configuration.interaction.retriesOnFailure {
        hints.append(FKAvatarI18n.retryHint)
      }
    default:
      accessibilityValue = nil
    }
    accessibilityHint = hints.isEmpty ? nil : hints.joined(separator: ". ")
  }
}
