import UIKit

/// Overlapping avatar stack with optional "+N" overflow affordance.
///
/// Child views are always ``FKAvatar`` instances — never standalone image views.
@MainActor
public final class FKAvatarGroup: UIView {
  /// Baseline copied by ``init(frame:)`` until replaced via ``configuration``.
  public static var defaultConfiguration: FKAvatarGroupConfiguration {
    get { FKAvatarGroupDefaults.configuration }
    set { FKAvatarGroupDefaults.configuration = newValue }
  }

  /// Layout and styling for the group.
  public var configuration: FKAvatarGroupConfiguration = FKAvatarGroup.defaultConfiguration {
    didSet { reloadAvatars() }
  }

  /// Avatar payloads rendered left-to-right (mirrored under RTL unless ``FKAvatarGroupConfiguration/direction`` overrides).
  public var avatars: [FKAvatarContent] = [] {
    didSet { reloadAvatars() }
  }

  /// Called when the overflow "+N" control is tapped.
  public var onOverflowTap: (() -> Void)?

  /// Called when a visible avatar is tapped; index matches the position in ``avatars`` (not z-order).
  public var onAvatarTap: ((Int) -> Void)?

  /// Cell-reuse helper: resets every child ``FKAvatar`` without changing configuration.
  public func resetForReuse() {
    avatarViews.forEach { $0.resetForReuse() }
  }

  private var avatarViews: [FKAvatar] = []
  private let overflowView = FKAvatarGroupOverflowView()
  private var latestMetrics = FKAvatarGroupLayoutEngine.Metrics(
    avatarFrames: [],
    overflowFrame: nil,
    totalSize: .zero
  )

  // MARK: - Life cycle

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  /// Creates a group with configuration and initial avatars.
  public convenience init(
    configuration: FKAvatarGroupConfiguration = FKAvatarGroup.defaultConfiguration,
    avatars: [FKAvatarContent] = []
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    self.avatars = avatars
  }

  public override var intrinsicContentSize: CGSize {
    latestMetrics.totalSize
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    applyLayoutMetrics()
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
      recomputeLayout()
      setNeedsLayout()
    }
  }

  // MARK: - Private

  private func commonInit() {
    isAccessibilityElement = false
    clipsToBounds = false
    overflowView.addTarget(self, action: #selector(handleOverflowTap), for: .touchUpInside)
    addSubview(overflowView)
    reloadAvatars()
  }

  private func reloadAvatars() {
    avatarViews.forEach { $0.removeFromSuperview() }
    avatarViews.removeAll()

    let visible = Array(avatars.prefix(configuration.maxVisible))
    for (index, content) in visible.enumerated() {
      let avatar = makeAvatar(for: content, index: index)
      avatarViews.append(avatar)
      addSubview(avatar)
    }

    let overflowCount = max(0, avatars.count - configuration.maxVisible)
    let showsOverflow = configuration.showsOverflowCount && overflowCount > 0
    overflowView.isHidden = !showsOverflow
    overflowView.overflowCount = overflowCount

    recomputeLayout()
    setNeedsLayout()
    invalidateIntrinsicContentSize()
  }

  private func makeAvatar(for content: FKAvatarContent, index: Int) -> FKAvatar {
    var avatarConfig = configuration.avatarConfiguration
    avatarConfig.layout.size = configuration.avatarSize
    avatarConfig.appearance.borderStyle = configuration.borderStyle
    avatarConfig.showsPresenceIndicator = false
    avatarConfig.presenceState = nil

    let avatar = FKAvatar(configuration: avatarConfig)
    avatar.displayName = content.displayName
    if let image = content.image {
      avatar.image = image
    } else if let url = content.imageURL {
      avatar.setImageURL(url, placeholder: nil)
    }
    avatar.tag = index
    avatar.addTarget(self, action: #selector(handleAvatarTap(_:)), for: .touchUpInside)
    return avatar
  }

  private func recomputeLayout() {
    let diameter = configuration.avatarSize.diameter
    let overflowCount = max(0, avatars.count - configuration.maxVisible)
    let showsOverflow = configuration.showsOverflowCount && overflowCount > 0
    overflowView.apply(diameter: diameter)

    latestMetrics = FKAvatarGroupLayoutEngine.layout(
      visibleAvatarCount: avatarViews.count,
      showsOverflow: showsOverflow,
      avatarDiameter: diameter,
      overlap: configuration.overlap,
      overflowDiameter: overflowView.intrinsicContentSize.width,
      direction: configuration.direction,
      isRTL: traitCollection.layoutDirection == .rightToLeft
    )
  }

  private func applyLayoutMetrics() {
    for (index, frame) in latestMetrics.avatarFrames.enumerated() where index < avatarViews.count {
      avatarViews[index].frame = frame
      // Rightmost avatar has highest z-order (Q2).
      avatarViews[index].layer.zPosition = CGFloat(index)
    }
    if let overflowFrame = latestMetrics.overflowFrame {
      overflowView.frame = overflowFrame
      overflowView.layer.zPosition = CGFloat(avatarViews.count)
    }
  }

  @objc private func handleOverflowTap() {
    onOverflowTap?()
  }

  @objc private func handleAvatarTap(_ sender: FKAvatar) {
    onAvatarTap?(sender.tag)
  }
}
