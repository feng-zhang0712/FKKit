import UIKit

@MainActor
final class FKTabBarItemCell: UICollectionViewCell {
  // MARK: - Model

  /// Immutable rendering input for a tab cell.
  ///
  /// The model is designed so the tab bar can re-apply it frequently during interactive progress
  /// without touching global state. `selectionProgress` is expected to be clamped to \([0, 1]\).
  struct Model {
    var item: FKTabBarItem
    var isSelected: Bool
    var appearance: FKTabBarAppearance
    var animation: FKTabBarAnimationConfiguration
    var overflowMode: FKTabBarTitleOverflowMode
    var selectionProgress: CGFloat
    var layoutDirection: FKTabBarItemLayoutDirection
    var rtlBehavior: FKTabBarRTLBehavior
    var longPressMinimumDuration: TimeInterval
    var isLongPressEnabled: Bool
    var maximumTitleLines: Int
    var itemInsets: NSDirectionalEdgeInsets
  }

  private let tabButton = FKButton()
  private var customBadgeView: UIView?
  private var allowsBadgeOverflow = false
  var onTap: ((FKButton) -> Void)?
  var onLongPress: ((FKButton) -> Void)?

  /// Returns the internal interactive button for same-module integrations.
  ///
  /// We intentionally keep this internal (instead of exposing a public mutable property on the cell)
  /// to preserve reuse invariants and avoid external replacement of the button instance.
  func interactiveButtonForIntegration() -> FKButton { tabButton }

  // MARK: - Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    applyBadgeOverflowHostingIfNeeded()
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    // Reuse must reset badge hosting and custom content, otherwise stale views may leak across items
    // when the collection view recycles cells during fast scrolling.
    clearBadges()
    customBadgeView?.removeFromSuperview()
    customBadgeView = nil
    tabButton.trailingImageView?.transform = .identity
    tabButton.setCustomContent(nil, for: .normal)
    tabButton.setCustomContent(nil, for: .selected)
    tabButton.setCustomContent(nil, for: .disabled)
    onTap = nil
    onLongPress = nil
    tabButton.onLongPressBegan = nil
    tabButton.onLongPressEnded = nil
  }

  // MARK: - Render

  func apply(
    _ model: Model,
    customization: FKTabBarCustomization?,
    badgeConfiguration: FKBadgeConfiguration?,
    badgeAnimation: FKBadgeAnimation
  ) {
    let appearance = model.appearance
    let item = model.item
    let selected = model.isSelected
    let progress = max(0, min(1, model.selectionProgress))

    let contentKind = FKTabBarItemButtonConfigurator.resolvedContentKind(for: item)
    applyContent(contentKind, selected: selected, item: item, customization: customization)
    FKTabBarItemButtonConfigurator.applyLayoutDirection(model.layoutDirection, to: tabButton)
    FKTabBarItemButtonConfigurator.applyRTLBehavior(model.rtlBehavior, to: tabButton)
    tabButton.longPressMinimumDuration = model.longPressMinimumDuration

    // Progressive font transition is approximated to avoid synthesizing fonts per frame.
    // When progress crosses midpoint, we switch to selected typography when enabled.
    let useSelectedFont: Bool
    if model.animation.allowsProgressiveFontTransition, progress > 0, progress < 1 {
      useSelectedFont = progress >= 0.5
    } else {
      useSelectedFont = selected
    }
    let baseFont = useSelectedFont ? appearance.typography.selectedFont : appearance.typography.normalFont

    let normalTitleColor = FKTabBarItemButtonConfigurator.resolvedNormalTitleColor(for: item, appearance: appearance)
    let selectedTitleColor = FKTabBarItemButtonConfigurator.resolvedSelectedTitleColor(for: item, appearance: appearance)

    let textColor: UIColor
    let iconColor: UIColor
    if !item.isEnabled {
      let disabledState = item.title.resolved(isSelected: selected, isEnabled: false)
      textColor = FKTabBarItemButtonConfigurator.resolvedSubtitleColor(
        for: disabledState,
        appearance: appearance,
        fallbackSelected: appearance.colors.disabledText
      )
      iconColor = appearance.colors.disabledIcon
    } else if selected || progress > 0 {
      // Prefer per-item title colors (composite bars often encode state in `FKTabBarItem` styles).
      textColor = interpolate(from: normalTitleColor, to: selectedTitleColor, progress: progress)
      if let imageConfiguration = item.image, imageConfiguration.normal.source != nil {
        let normalTint = imageConfiguration.normal.style.tintColor ?? appearance.colors.normalIcon
        let selectedTint = (imageConfiguration.selected ?? imageConfiguration.normal).style.tintColor ?? appearance.colors.selectedIcon
        iconColor = interpolate(from: normalTint, to: selectedTint, progress: progress)
      } else {
        iconColor = interpolate(from: appearance.colors.normalIcon, to: appearance.colors.selectedIcon, progress: progress)
      }
    } else {
      textColor = normalTitleColor
      if let imageConfiguration = item.image, imageConfiguration.normal.source != nil {
        iconColor = imageConfiguration.normal.style.tintColor ?? appearance.colors.normalIcon
      } else {
        iconColor = appearance.colors.normalIcon
      }
    }
    let titleText = resolvedTitle(for: item, isSelected: selected)
    let lineBreakMode: NSLineBreakMode
    let adjustsFontSizeToFitWidth: Bool
    let minimumScaleFactor: CGFloat

    if titleText.isEmpty {
      lineBreakMode = .byClipping
      adjustsFontSizeToFitWidth = false
      minimumScaleFactor = 1
    } else {
      let layout = FKTabBarItemButtonConfigurator.resolvedTitleLayout(
        titleText: titleText,
        overflowMode: model.overflowMode
      )
      lineBreakMode = layout.0
      adjustsFontSizeToFitWidth = layout.1
      minimumScaleFactor = layout.2
    }

    tabButton.isEnabled = item.isEnabled
    tabButton.isSelected = selected
    let label = FKButton.LabelAttributes(
      text: titleText,
      font: baseFont,
      color: textColor,
      alignment: .center,
      numberOfLines: max(1, model.maximumTitleLines),
      lineBreakMode: lineBreakMode,
      adjustsFontForContentSizeCategory: appearance.typography.adjustsForContentSizeCategory,
      textStyle: .subheadline,
      adjustsFontSizeToFitWidth: adjustsFontSizeToFitWidth,
      minimumScaleFactor: minimumScaleFactor
    )
    tabButton.setTitle(label, for: .normal)
    tabButton.setTitle(label, for: .selected)
    tabButton.setTitle(label, for: .disabled)

    // Subtitle configuration priority: item override > global appearance.
    if let subtitleConfiguration = FKTabBarItemButtonConfigurator.resolvedSubtitleConfiguration(
      for: item,
      appearance: appearance
    ) {
      let subtitleState = subtitleConfiguration.resolved(isSelected: selected, isEnabled: item.isEnabled)
      if let subtitle = subtitleState.text, !subtitle.isEmpty {
        let subtitleColor: UIColor
        if !item.isEnabled {
          subtitleColor = subtitleState.style.color
        } else if subtitleConfiguration.selected == nil, selected || progress > 0 {
          // Match title color when no per-state subtitle override is configured.
          subtitleColor = textColor
        } else if selected || progress > 0 {
          let normalColor = FKTabBarItemButtonConfigurator.resolvedSubtitleColor(
            for: subtitleConfiguration.normal,
            appearance: appearance,
            fallbackSelected: appearance.colors.normalText
          )
          let selectedColor = subtitleConfiguration.selected.map {
            FKTabBarItemButtonConfigurator.resolvedSubtitleColor(
              for: $0,
              appearance: appearance,
              fallbackSelected: appearance.colors.selectedText
            )
          } ?? appearance.colors.selectedText
          subtitleColor = interpolate(from: normalColor, to: selectedColor, progress: progress)
        } else {
          subtitleColor = subtitleState.style.color
        }
        let spacingToTitle = item.subtitle?.spacingToNextText ?? subtitleConfiguration.spacingToNextText
        let attrs = FKButton.LabelAttributes(
          text: subtitle,
          font: subtitleState.style.font,
          color: subtitleColor,
          alignment: subtitleState.style.alignment,
          numberOfLines: subtitleState.style.numberOfLines,
          lineBreakMode: subtitleState.style.lineBreakMode,
          adjustsFontForContentSizeCategory: subtitleState.style.adjustsForContentSizeCategory,
          textStyle: .caption2,
          adjustsFontSizeToFitWidth: subtitleState.style.adjustsFontSizeToFitWidth,
          minimumScaleFactor: subtitleState.style.minimumScaleFactor,
          contentInsets: .init(
            top: spacingToTitle,
            leading: subtitleState.style.contentInsets.leading,
            bottom: subtitleState.style.contentInsets.bottom,
            trailing: subtitleState.style.contentInsets.trailing
          )
        )
        tabButton.setSubtitle(attrs, for: .normal)
        tabButton.setSubtitle(attrs, for: .selected)
        tabButton.setSubtitle(attrs, for: .disabled)
      } else {
        tabButton.setSubtitle(nil, for: .normal)
        tabButton.setSubtitle(nil, for: .selected)
        tabButton.setSubtitle(nil, for: .disabled)
      }
    } else {
      tabButton.setSubtitle(nil, for: .normal)
      tabButton.setSubtitle(nil, for: .selected)
      tabButton.setSubtitle(nil, for: .disabled)
    }
    tabButton.tintColor = iconColor
    applyAccessory(
      item: item,
      textColor: textColor
    )
    customization?.configure(button: tabButton, item: item, isSelected: selected)

    // Accessibility is hosted by `FKButton` so VoiceOver focus matches the tappable element.
    tabButton.isAccessibilityElement = true
    tabButton.accessibilityLabel = item.accessibilityLabel ?? item.title.normal.text ?? item.id
    tabButton.accessibilityHint = item.accessibilityHint
    var traits: UIAccessibilityTraits = [.button]
    if selected { traits.insert(.selected) }
    if !item.isEnabled { traits.insert(.notEnabled) }
    tabButton.accessibilityTraits = traits
    tabButton.accessibilityValue = resolvedAccessibilityValue(
      item: item,
      isSelected: selected
    )

    applyBadge(
      item.badge,
      item: item,
      isSelected: selected,
      customization: customization,
      badgeConfiguration: badgeConfiguration,
      badgeAnimation: badgeAnimation
    )
    // After badge + selection styling: keep overflow clipping off and pin insets last.
    FKTabBarItemButtonConfigurator.applyItemInsets(model.itemInsets, to: tabButton)
    applyBadgeOverflowHostingIfNeeded()

    // Long-press is opt-in. Keeping callbacks nil avoids interfering with normal taps.
    if model.isLongPressEnabled {
      tabButton.onLongPressBegan = { [weak self] in
        guard let self else { return }
        self.onLongPress?(self.tabButton)
      }
    } else {
      tabButton.onLongPressBegan = nil
    }
  }

  // MARK: - View Setup

  private func setup() {
    // Avoid inheriting superview/readable margins. During rotation/split view, UIKit can change
    // effective layout margins, which would unintentionally shrink the button's available width
    // and can trigger constraint conflicts inside FKButton's internal stack layout.
    contentView.preservesSuperviewLayoutMargins = false
    contentView.layoutMargins = .zero
    tabButton.translatesAutoresizingMaskIntoConstraints = false
    tabButton.isUserInteractionEnabled = true
    tabButton.contentHorizontalAlignment = .center
    tabButton.contentVerticalAlignment = .center
    contentView.addSubview(tabButton)

    isAccessibilityElement = false
    contentView.isAccessibilityElement = false

    // Finger taps on `FKButton` (a `UIControl` subclass) deliver `.touchUpInside`; `.primaryActionTriggered`
    // is mainly wired for `UIButton` / accessibility / keyboard (see ProgressBar example comments).
    tabButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

    NSLayoutConstraint.activate([
      tabButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      tabButton.topAnchor.constraint(equalTo: contentView.topAnchor),
      tabButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      tabButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
    ])
  }

  @objc private func handleTap() {
    onTap?(tabButton)
  }

  // MARK: - Badge

  private func applyBadge(
    _ badge: FKTabBarBadgeConfiguration,
    item: FKTabBarItem,
    isSelected: Bool,
    customization: FKTabBarCustomization?,
    badgeConfiguration: FKBadgeConfiguration?,
    badgeAnimation: FKBadgeAnimation
  ) {
    clearBadges()
    customBadgeView?.removeFromSuperview()
    customBadgeView = nil

    // Badge anchor resolution is centralized to keep one single source of truth.
    let target = FKTabBarBadgeAnchorResolver.resolveTargetView(button: tabButton)
    if let badgeConfiguration {
      target.fk_badge.configuration = badgeConfiguration
    }
    target.fk_badge.setAnchor(badge.anchor, offset: badge.offset)

    switch badge.state.resolved(isSelected: isSelected, isEnabled: item.isEnabled) {
    case .none:
      break
    case .dot:
      target.fk_badge.showDot(animated: false, animation: badgeAnimation)
    case .count(let count):
      target.fk_badge.showCount(count, animated: false, animation: badgeAnimation)
    case .text(let text):
      target.fk_badge.showText(text, animated: false, animation: badgeAnimation)
    case .custom:
      guard let custom = customization?.customBadgeView(for: item) else { return }
      custom.translatesAutoresizingMaskIntoConstraints = false
      contentView.addSubview(custom)
      NSLayoutConstraint.activate([
        custom.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
        custom.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -2),
      ])
      customBadgeView = custom
    }

    allowsBadgeOverflow = badge.avoidsClipping && hasVisibleTabBadge(
      badge: badge,
      item: item,
      isSelected: isSelected,
      customization: customization
    )
    applyBadgeOverflowHostingIfNeeded()
  }

  private func applyBadgeOverflowHostingIfNeeded() {
    guard allowsBadgeOverflow else { return }
    contentView.clipsToBounds = false
    clipsToBounds = false
    tabButton.clipsToBounds = false
    tabButton.contentContainerView.clipsToBounds = false
  }

  private func hasVisibleTabBadge(
    badge: FKTabBarBadgeConfiguration,
    item: FKTabBarItem,
    isSelected: Bool,
    customization: FKTabBarCustomization?
  ) -> Bool {
    switch badge.state.resolved(isSelected: isSelected, isEnabled: item.isEnabled) {
    case .none:
      return false
    case .custom:
      return customization?.customBadgeView(for: item) != nil
    case .dot, .count, .text:
      return true
    }
  }

  func contentFrame(in targetView: UIView) -> CGRect {
    // Used by indicator follow modes that want to track rendered title/icon bounds rather than the full cell.
    tabButton.layoutIfNeeded()
    let source = tabButton.stackView
    guard !source.bounds.isEmpty else { return .zero }
    return targetView.convert(source.bounds, from: source)
  }

  private func applyAccessory(
    item: FKTabBarItem,
    textColor: UIColor
  ) {
    guard let icon = item.accessoryIcon else {
      [.normal, .selected, .disabled].forEach { tabButton.setTrailingImage(nil, for: $0) }
      return
    }
    // Do not clear the trailing image slot before re-applying — host code may be animating
    // ``FKButton/trailingImageView`` (for example via ``FKTabBar/visibleItemAccessoryView(at:)``).
    FKTabBarItemButtonConfigurator.applyIconAccessory(
      to: tabButton,
      icon: icon,
      textColor: textColor
    )
  }

  // MARK: - Content

  private func applyContent(
    _ content: FKTabBarItemButtonConfigurator.ContentKind,
    selected: Bool,
    item: FKTabBarItem,
    customization: FKTabBarCustomization?
  ) {
    FKTabBarItemButtonConfigurator.applyContentKind(content, to: tabButton, item: item, customization: customization)
  }

  private func resolvedTitle(for item: FKTabBarItem, isSelected: Bool) -> String {
    let state = item.title.resolved(isSelected: isSelected, isEnabled: item.isEnabled)
    return state.text ?? ""
  }

  private func clearBadges() {
    allowsBadgeOverflow = false
    // Reset clipping defaults because some badge placements require overflow.
    contentView.clipsToBounds = true
    clipsToBounds = true
    tabButton.clipsToBounds = true
    tabButton.contentContainerView.clipsToBounds = true
    [tabButton, tabButton.imageView, tabButton.leadingImageView, tabButton.trailingImageView].forEach { view in
      view?.fk_badge.clear(animated: false)
    }
  }

  private func resolvedAccessibilityValue(item: FKTabBarItem, isSelected: Bool) -> String? {
    let selectedToken = isSelected ? FKUIKitI18n.string("fkuikit.tabbar.selected") : nil
    if let explicit = item.badge.accessibilityValue, !explicit.isEmpty {
      if let selectedToken {
        return "\(selectedToken), \(explicit)"
      }
      return explicit
    }
    let badgeToken: String? = {
      switch item.badge.state.resolved(isSelected: isSelected, isEnabled: item.isEnabled) {
      case .none:
        return nil
      case .dot:
        return FKUIKitI18n.string("fkuikit.tabbar.badge")
      case .count(let value):
        return FKUIKitI18n.format("fkuikit.tabbar.badge_count", max(0, value))
      case .text(let text):
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? FKUIKitI18n.string("fkuikit.tabbar.badge") : FKUIKitI18n.format("fkuikit.tabbar.badge_text", trimmed)
      case .custom:
        return FKUIKitI18n.string("fkuikit.tabbar.badge_custom")
      }
    }()
    switch (selectedToken, badgeToken) {
    case let (selected?, badge?):
      return "\(selected), \(badge)"
    case let (selected?, nil):
      return selected
    case let (nil, badge?):
      return badge
    case (nil, nil):
      return nil
    }
  }

  private func interpolate(from: UIColor, to: UIColor, progress: CGFloat) -> UIColor {
    var fr: CGFloat = 0
    var fg: CGFloat = 0
    var fb: CGFloat = 0
    var fa: CGFloat = 0
    var tr: CGFloat = 0
    var tg: CGFloat = 0
    var tb: CGFloat = 0
    var ta: CGFloat = 0
    guard from.getRed(&fr, green: &fg, blue: &fb, alpha: &fa),
          to.getRed(&tr, green: &tg, blue: &tb, alpha: &ta) else {
      return progress < 0.5 ? from : to
    }
    let p = max(0, min(1, progress))
    return UIColor(
      red: fr + (tr - fr) * p,
      green: fg + (tg - fg) * p,
      blue: fb + (tb - fb) * p,
      alpha: fa + (ta - fa) * p
    )
  }
}

