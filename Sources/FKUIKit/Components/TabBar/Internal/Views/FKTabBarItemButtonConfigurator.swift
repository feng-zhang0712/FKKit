import UIKit

/// Shared ``FKButton`` assembly for ``FKTabBarItemCell`` and ``FKTabBarItemContentMeasurer``.
@MainActor
enum FKTabBarItemButtonConfigurator {
  enum ContentKind {
    case textOnly
    case imageOnly
    case textAndImage
    case custom
  }

  // MARK: - Resolution

  static func resolvedContentKind(for item: FKTabBarItem) -> ContentKind {
    if item.customContentIdentifier != nil { return .custom }
    let hasText = !(item.title.normal.text ?? "").isEmpty
    let hasImage = item.image?.normal.source != nil
    if hasText && hasImage { return .textAndImage }
    if hasImage { return .imageOnly }
    return .textOnly
  }

  static func resolvedImageSlot(for configuration: FKTabBarImageConfiguration?) -> FKButton.ImageSlot {
    let position = configuration?.normal.style.position ?? .leading
    switch position {
    case .leading:
      return .leading
    case .trailing:
      return .trailing
    }
  }

  /// Item-level subtitle wins; otherwise falls back to ``FKTabBarAppearance/subtitleConfiguration``.
  static func resolvedSubtitleConfiguration(
    for item: FKTabBarItem,
    appearance: FKTabBarAppearance
  ) -> FKTabBarTextConfiguration? {
    if let itemSubtitle = item.subtitle {
      return itemSubtitle
    }
    let global = appearance.subtitleConfiguration
    let text = global.normal.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    guard !text.isEmpty else { return nil }
    return global
  }

  static func resolveImage(_ source: FKTabBarImageSource?) -> UIImage? {
    guard let source else { return nil }
    switch source {
    case .image(let image):
      return image
    case .systemSymbol(let name):
      return UIImage(systemName: name)
    case .asset(let name, let bundle):
      return UIImage(named: name, in: bundle, compatibleWith: nil)
    case .remote(_, let placeholder):
      return placeholder
    }
  }

  static func resolvedTitleLayout(
    titleText: String,
    overflowMode: FKTabBarTitleOverflowMode
  ) -> (NSLineBreakMode, Bool, CGFloat) {
    guard !titleText.isEmpty else {
      return (.byClipping, false, 1)
    }
    switch overflowMode {
    case .truncate, .automaticWidth, .fixedWidth:
      return (.byTruncatingTail, false, 1)
    case .shrink(let factor):
      return (.byClipping, true, max(0.5, min(1.0, factor)))
    case .wrap:
      return (.byWordWrapping, false, 1)
    }
  }

  /// Returns the unscaled typography font that produces the wider title after Dynamic Type scaling.
  ///
  /// ``FKButton`` applies Dynamic Type itself; never pass an already scaled font into ``FKButton/LabelAttributes``.
  static func widerTitleFont(for text: String, typography: FKTabBarAppearance.Typography) -> UIFont {
    guard !text.isEmpty else {
      return typography.normalFont
    }
    let metrics = UIFontMetrics(forTextStyle: .subheadline)
    let normalForMeasure = typography.adjustsForContentSizeCategory
      ? metrics.scaledFont(for: typography.normalFont)
      : typography.normalFont
    let selectedForMeasure = typography.adjustsForContentSizeCategory
      ? metrics.scaledFont(for: typography.selectedFont)
      : typography.selectedFont
    let normalWidth = ceil((text as NSString).size(withAttributes: [.font: normalForMeasure]).width)
    let selectedWidth = ceil((text as NSString).size(withAttributes: [.font: selectedForMeasure]).width)
    return selectedWidth >= normalWidth ? typography.selectedFont : typography.normalFont
  }

  // MARK: - Button mutation

  static func applyItemInsets(_ insets: NSDirectionalEdgeInsets, to button: FKButton) {
    let sharedAppearance = FKButton.Appearance(
      backgroundColor: .clear,
      contentInsets: insets
    )
    button.setAppearance(sharedAppearance, for: .normal)
    button.setAppearance(sharedAppearance, for: .selected)
    button.setAppearance(sharedAppearance, for: .disabled)
  }

  static func applyLayoutDirection(_ direction: FKTabBarItemLayoutDirection, to button: FKButton) {
    switch direction {
    case .horizontal:
      button.axis = .horizontal
    case .vertical:
      button.axis = .vertical
    }
  }

  static func applyRTLBehavior(_ behavior: FKTabBarRTLBehavior, to button: FKButton) {
    switch behavior {
    case .automatic:
      button.semanticContentAttribute = .unspecified
    case .forceLeftToRight:
      button.semanticContentAttribute = .forceLeftToRight
    case .forceRightToLeft:
      button.semanticContentAttribute = .forceRightToLeft
    }
  }

  static func resetButtonContent(_ button: FKButton, preservingTrailingSlot: Bool = false) {
    let states: [UIControl.State] = [.normal, .selected, .disabled]
    states.forEach {
      button.setCenterImage(nil, for: $0)
      button.setLeadingImage(nil, for: $0)
      if !preservingTrailingSlot {
        button.setTrailingImage(nil, for: $0)
      }
      button.setSubtitle(nil, for: $0)
      button.setCustomContent(nil, for: $0)
    }
  }

  static func applyContentKind(
    _ kind: ContentKind,
    to button: FKButton,
    item: FKTabBarItem,
    customization: FKTabBarCustomization?
  ) {
    resetButtonContent(button, preservingTrailingSlot: item.accessoryIcon != nil)

    switch kind {
    case .textOnly:
      button.content = .textOnly
    case .imageOnly:
      button.content = .imageOnly
      applyImageConfiguration(item.image, to: button, slot: .center, singleStateOnly: false)
    case .textAndImage:
      let slot = resolvedImageSlot(for: item.image)
      button.content = .textAndImage(slot == .trailing ? .trailing : .leading)
      applyImageConfiguration(item.image, to: button, slot: slot, singleStateOnly: false)
    case .custom:
      button.content = .custom
      let normalContent = FKButton.CustomContent(
        view: customization?.customContentView(for: item),
        spacingToAdjacentContent: 0
      )
      button.setCustomContent(normalContent, for: .normal)
      button.setCustomContent(normalContent, for: .selected)
      button.setCustomContent(normalContent, for: .disabled)
    }
  }

  static func applyImageConfiguration(
    _ configuration: FKTabBarImageConfiguration?,
    to button: FKButton,
    slot: FKButton.ImageSlot,
    singleStateOnly: Bool
  ) {
    guard let configuration else { return }
    let normalState = configuration.normal
    if singleStateOnly {
      let imageAttributes = FKButton.ImageAttributes(
        image: resolveImage(normalState.source),
        tintColor: normalState.style.tintColor,
        fixedSize: normalState.style.fixedSize,
        spacingToTitle: normalState.style.spacingToTitle
      )
      button.setImage(imageAttributes, slot: slot, for: .normal)
      button.setImage(imageAttributes, slot: slot, for: .selected)
      button.setImage(imageAttributes, slot: slot, for: .disabled)
      return
    }

    let selectedState = configuration.selected ?? normalState
    let disabledState = configuration.disabled ?? normalState
    let normalImage = FKButton.ImageAttributes(
      image: resolveImage(normalState.source),
      tintColor: normalState.style.tintColor,
      fixedSize: normalState.style.fixedSize,
      spacingToTitle: normalState.style.spacingToTitle
    )
    let selectedImage = FKButton.ImageAttributes(
      image: resolveImage(selectedState.source),
      tintColor: selectedState.style.tintColor,
      fixedSize: selectedState.style.fixedSize,
      spacingToTitle: selectedState.style.spacingToTitle
    )
    let disabledImage = FKButton.ImageAttributes(
      image: resolveImage(disabledState.source),
      tintColor: disabledState.style.tintColor,
      fixedSize: disabledState.style.fixedSize,
      spacingToTitle: disabledState.style.spacingToTitle
    )
    button.setImage(normalImage, slot: slot, for: .normal)
    button.setImage(selectedImage, slot: slot, for: .selected)
    button.setImage(disabledImage, slot: slot, for: .disabled)
  }

  static func subtitleLabelAttributes(
    from configuration: FKTabBarTextConfiguration,
    isSelected: Bool,
    isEnabled: Bool,
    spacingToTitle: CGFloat
  ) -> FKButton.LabelAttributes? {
    let subtitleState = configuration.resolved(isSelected: isSelected, isEnabled: isEnabled)
    guard let subtitle = subtitleState.text, !subtitle.isEmpty else { return nil }
    return FKButton.LabelAttributes(
      text: subtitle,
      font: subtitleState.style.font,
      color: subtitleState.style.color,
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
  }

  static func applyIconAccessory(
    to button: FKButton,
    icon: FKTabBarAccessoryIconConfiguration,
    textColor: UIColor
  ) {
    func imageAttributes(for state: FKTabBarAccessoryIconConfiguration.State) -> FKButton.ImageAttributes? {
      guard let source = state.source else { return nil }
      let style = state.style
      let symbolConfiguration = UIImage.SymbolConfiguration(
        pointSize: style.pointSize,
        weight: style.weight.uiImageWeight
      )
      let tint = style.tintColor ?? textColor
      let fixedSize = style.fixedSize
        ?? CGSize(width: style.pointSize, height: style.pointSize)

      switch source {
      case .systemSymbol(let name):
        return FKButton.ImageAttributes(
          systemName: name,
          renderingMode: .alwaysTemplate,
          symbolConfiguration: symbolConfiguration,
          tintColor: tint,
          fixedSize: fixedSize,
          spacingToTitle: style.spacingToTitle
        )
      case .image(let image):
        return FKButton.ImageAttributes(
          image: image,
          renderingMode: .alwaysTemplate,
          tintColor: tint,
          fixedSize: fixedSize,
          spacingToTitle: style.spacingToTitle
        )
      case .asset, .remote:
        guard let image = resolveImage(source) else { return nil }
        return FKButton.ImageAttributes(
          image: image,
          renderingMode: .alwaysTemplate,
          tintColor: tint,
          fixedSize: fixedSize,
          spacingToTitle: style.spacingToTitle
        )
      }
    }

    let states: [(FKTabBarAccessoryIconConfiguration.State, UIControl.State)] = [
      (icon.normal, .normal),
      (icon.selected ?? icon.normal, .selected),
      (icon.disabled ?? icon.normal, .disabled),
    ]
    for (iconState, controlState) in states {
      button.setTrailingImage(imageAttributes(for: iconState), for: controlState)
    }
  }
}
