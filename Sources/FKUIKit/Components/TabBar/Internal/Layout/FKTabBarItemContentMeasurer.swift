import UIKit

/// Measures tab item content using the same ``FKButton`` layout path as ``FKTabBarItemCell``.
///
/// Keeps collection item width aligned with on-screen ``FKButton/intrinsicContentSize`` so center
/// alignment does not introduce extra slack between ``FKButton/contentContainerView`` and ``FKButton/stackView``.
@MainActor
enum FKTabBarItemContentMeasurer {
  private static let prototype: FKButton = {
    let button = FKButton()
    button.contentHorizontalAlignment = .center
    button.contentVerticalAlignment = .center
    return button
  }()

  /// Returns the laid-out ``FKButton`` size for a tab item, including ``FKTabBarLayoutConfiguration/itemInsets``.
  static func measuredContentSize(
    item: FKTabBarItem,
    layout: FKTabBarLayoutConfiguration,
    appearance: FKTabBarAppearance,
    effectiveOverflowMode: FKTabBarTitleOverflowMode,
    maximumTitleLines: Int
  ) -> CGSize {
    guard item.customContentIdentifier == nil else { return .zero }

    configurePrototype(
      item: item,
      layout: layout,
      appearance: appearance,
      effectiveOverflowMode: effectiveOverflowMode,
      maximumTitleLines: maximumTitleLines
    )

    let size = prototype.intrinsicContentSize
    guard size.width > 0, size.width != UIView.noIntrinsicMetric else { return .zero }
    return CGSize(
      width: ceil(size.width),
      height: ceil(max(size.height, 0))
    )
  }

  // MARK: - Prototype configuration

  private static func configurePrototype(
    item: FKTabBarItem,
    layout: FKTabBarLayoutConfiguration,
    appearance: FKTabBarAppearance,
    effectiveOverflowMode: FKTabBarTitleOverflowMode,
    maximumTitleLines: Int
  ) {
    resetPrototypeContent()

    applyContentKind(for: item, layout: layout)
    applyItemInsets(layout.itemInsets, to: prototype)

    let titleText = item.title.normal.text ?? ""
    let titleFont = widerTitleFont(for: titleText, typography: appearance.typography)
    let (lineBreakMode, adjustsFontSizeToFitWidth, minimumScaleFactor) = resolvedTitleLayout(
      titleText: titleText,
      overflowMode: effectiveOverflowMode
    )

    let label = FKButton.LabelAttributes(
      text: titleText,
      font: titleFont,
      color: appearance.colors.normalText,
      alignment: .center,
      numberOfLines: max(1, maximumTitleLines),
      lineBreakMode: lineBreakMode,
      adjustsFontForContentSizeCategory: appearance.typography.adjustsForContentSizeCategory,
      textStyle: .subheadline,
      adjustsFontSizeToFitWidth: adjustsFontSizeToFitWidth,
      minimumScaleFactor: minimumScaleFactor
    )
    prototype.setTitle(label, for: .normal)
    prototype.setTitle(label, for: .selected)
    prototype.setTitle(label, for: .disabled)

    applySubtitleIfNeeded(for: item)
    applyAccessoryIfNeeded(for: item, textColor: appearance.colors.normalText)
  }

  private static func resetPrototypeContent() {
    let states: [UIControl.State] = [.normal, .selected, .disabled]
    states.forEach {
      prototype.setCenterImage(nil, for: $0)
      prototype.setLeadingImage(nil, for: $0)
      prototype.setTrailingImage(nil, for: $0)
      prototype.setSubtitle(nil, for: $0)
      prototype.setCustomContent(nil, for: $0)
    }
  }

  private static func applyContentKind(for item: FKTabBarItem, layout: FKTabBarLayoutConfiguration) {
    switch layout.itemLayoutDirection {
    case .horizontal:
      prototype.axis = .horizontal
    case .vertical:
      prototype.axis = .vertical
    }

    let hasText = !(item.title.normal.text ?? "").isEmpty
    let hasImage = item.image?.normal.source != nil

    switch (hasText, hasImage) {
    case (_, false) where !hasText:
      prototype.content = .textOnly
    case (false, true):
      prototype.content = .imageOnly
      applyImageConfiguration(item.image, slot: .center)
    case (true, true):
      let slot = resolvedImageSlot(for: item.image)
      prototype.content = .textAndImage(slot == .trailing ? .trailing : .leading)
      applyImageConfiguration(item.image, slot: slot)
    default:
      prototype.content = .textOnly
    }
  }

  private static func applyItemInsets(_ insets: NSDirectionalEdgeInsets, to button: FKButton) {
    let sharedAppearance = FKButton.Appearance(
      backgroundColor: .clear,
      contentInsets: insets
    )
    button.setAppearance(sharedAppearance, for: .normal)
    button.setAppearance(sharedAppearance, for: .selected)
    button.setAppearance(sharedAppearance, for: .disabled)
  }

  private static func applySubtitleIfNeeded(for item: FKTabBarItem) {
    guard let subtitleConfiguration = item.subtitle else {
      prototype.setSubtitle(nil, for: .normal)
      prototype.setSubtitle(nil, for: .selected)
      prototype.setSubtitle(nil, for: .disabled)
      return
    }

    let subtitleState = subtitleConfiguration.resolved(isSelected: false, isEnabled: item.isEnabled)
    guard let subtitle = subtitleState.text, !subtitle.isEmpty else {
      prototype.setSubtitle(nil, for: .normal)
      prototype.setSubtitle(nil, for: .selected)
      prototype.setSubtitle(nil, for: .disabled)
      return
    }

    let attrs = FKButton.LabelAttributes(
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
        top: subtitleConfiguration.spacingToNextText,
        leading: subtitleState.style.contentInsets.leading,
        bottom: subtitleState.style.contentInsets.bottom,
        trailing: subtitleState.style.contentInsets.trailing
      )
    )
    prototype.setSubtitle(attrs, for: .normal)
    prototype.setSubtitle(attrs, for: .selected)
    prototype.setSubtitle(attrs, for: .disabled)
  }

  private static func applyAccessoryIfNeeded(for item: FKTabBarItem, textColor: UIColor) {
    switch item.accessory.kind {
    case .none, .custom:
      return
    case .chevron:
      let image = UIImage(systemName: "chevron.down")?.withRenderingMode(.alwaysTemplate)
      let tint = item.accessory.tintColor ?? textColor
      let attrs = FKButton.ImageAttributes(
        image: image,
        tintColor: tint,
        spacingToTitle: item.accessory.spacing
      )
      prototype.setTrailingImage(attrs, for: .normal)
      prototype.setTrailingImage(attrs, for: .selected)
      prototype.setTrailingImage(attrs, for: .disabled)
    }
  }

  private static func applyImageConfiguration(_ configuration: FKTabBarImageConfiguration?, slot: FKButton.ImageSlot) {
    guard let configuration else { return }
    let normalState = configuration.normal
    let imageAttributes = FKButton.ImageAttributes(
      image: resolveImage(normalState.source),
      tintColor: normalState.style.tintColor,
      fixedSize: normalState.style.fixedSize,
      spacingToTitle: normalState.style.spacingToTitle
    )
    prototype.setImage(imageAttributes, slot: slot, for: .normal)
    prototype.setImage(imageAttributes, slot: slot, for: .selected)
    prototype.setImage(imageAttributes, slot: slot, for: .disabled)
  }

  private static func resolvedImageSlot(for configuration: FKTabBarImageConfiguration?) -> FKButton.ImageSlot {
    let position = configuration?.normal.style.position ?? .leading
    switch position {
    case .leading:
      return .leading
    case .trailing:
      return .trailing
    }
  }

  private static func resolveImage(_ source: FKTabBarImageSource?) -> UIImage? {
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

  /// Returns the unscaled typography font that produces the wider title after Dynamic Type scaling.
  ///
  /// ``FKButton`` applies ``FKButtonLabelConfiguration/adjustsFontForContentSizeCategory`` itself;
  /// passing an already scaled font into ``FKButton/LabelAttributes`` triggers a runtime exception.
  private static func widerTitleFont(for text: String, typography: FKTabBarAppearance.Typography) -> UIFont {
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

  private static func resolvedTitleLayout(
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
}
