import FKCoreKit
import UIKit

/// Fixed-size SF Symbol or template image container with optional background fill.
///
/// Attach badges via ``UIView/fk_badge``; call ``FKIconView/applyDefaultBadgeAnchor()`` for the recommended top-trailing placement.
@MainActor
public final class FKIconView: UIView {
  public static var defaultConfiguration: FKIconViewConfiguration {
    get { FKIconViewDefaults.configuration }
    set { FKIconViewDefaults.configuration = newValue }
  }

  public var configuration: FKIconViewConfiguration = FKIconView.defaultConfiguration {
    didSet { applyConfiguration() }
  }

  /// SF Symbol name when ``image`` is `nil`.
  public var symbolName: String? {
    didSet {
      guard oldValue != symbolName else { return }
      refreshContent()
    }
  }

  /// Custom bitmap; takes precedence over ``symbolName`` when non-`nil`.
  public var image: UIImage? {
    didSet {
      guard oldValue !== image else { return }
      refreshContent()
    }
  }

  /// Glyph tint override; `nil` uses ``FKIconViewAppearanceConfiguration/defaultTintColor``.
  public var iconTintColor: UIColor? {
    didSet {
      guard oldValue != iconTintColor else { return }
      applyTint()
    }
  }

  private let backgroundPlate = UIView()
  private let glyphView = UIImageView()

  public override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public convenience init(
    configuration: FKIconViewConfiguration = FKIconView.defaultConfiguration,
    symbolName: String? = nil,
    image: UIImage? = nil,
    tintColor: UIColor? = nil
  ) {
    self.init(frame: .zero)
    self.configuration = configuration
    self.symbolName = symbolName
    self.image = image
    self.iconTintColor = tintColor
  }

  public override var intrinsicContentSize: CGSize {
    let side = configuration.layout.size.side
    return CGSize(width: side, height: side)
  }

  public override var semanticContentAttribute: UISemanticContentAttribute {
    didSet {
      guard oldValue != semanticContentAttribute else { return }
      setNeedsLayout()
      fk_badge.reattachIfNeeded()
    }
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    backgroundPlate.frame = bounds
    applyBackgroundChrome()

    let glyphSide = configuration.layout.size.symbolPointSize
    glyphView.frame = CGRect(
      x: (bounds.width - glyphSide) / 2,
      y: (bounds.height - glyphSide) / 2,
      width: glyphSide,
      height: glyphSide
    )
  }

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
      refreshContent()
    } else if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
      setNeedsLayout()
      fk_badge.reattachIfNeeded()
    } else if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      setNeedsLayout()
    }
  }

  /// Applies ``FKWidgetIcon`` content using the shared widget icon payload (Chip, Tag).
  public func applyWidgetIcon(_ icon: FKWidgetIcon?) {
    FKIconViewWidgetIconRenderer.apply(icon, to: self)
  }

  /// Configures ``FKBadgeController`` with the default top-trailing anchor and size-aware offset.
  ///
  /// Call again after changing ``FKIconViewConfiguration/layout/size`` so the offset matches the new container side.
  public func applyDefaultBadgeAnchor() {
    fk_badge.setAnchor(
      .topTrailing,
      offset: FKWidgetLayoutMetrics.iconViewBadgeOffset(side: configuration.layout.size.side)
    )
  }

  private func commonInit() {
    clipsToBounds = false
    isUserInteractionEnabled = false
    setContentHuggingPriority(.required, for: .horizontal)
    setContentHuggingPriority(.required, for: .vertical)
    setContentCompressionResistancePriority(.required, for: .horizontal)
    setContentCompressionResistancePriority(.required, for: .vertical)

    backgroundPlate.isUserInteractionEnabled = false
    glyphView.contentMode = .scaleAspectFit
    glyphView.isUserInteractionEnabled = false

    addSubview(backgroundPlate)
    addSubview(glyphView)

    applyConfiguration()
  }

  private func applyConfiguration() {
    invalidateIntrinsicContentSize()
    setNeedsLayout()
    refreshContent()
    updateAccessibility()
  }

  private func refreshContent() {
    let resolved = FKIconViewRenderer.resolve(
      symbolName: symbolName,
      image: image,
      configuration: configuration
    )
    glyphView.image = resolved.image
    glyphView.isHidden = resolved.image == nil
    if resolved.isPlaceholder {
      glyphView.alpha = 0.35
    } else {
      glyphView.alpha = 1
    }
    applyTint(renderingMode: resolved.renderingMode)
    setNeedsLayout()
  }

  private func applyTint(renderingMode: UIImage.RenderingMode? = nil) {
    let mode = renderingMode ?? glyphView.image?.renderingMode ?? .alwaysTemplate
    if mode == .alwaysTemplate {
      glyphView.tintColor = iconTintColor ?? configuration.appearance.defaultTintColor
    } else {
      glyphView.tintColor = nil
    }
  }

  private func applyBackgroundChrome() {
    let style = configuration.appearance.backgroundStyle
    backgroundPlate.backgroundColor = FKIconViewRenderer.backgroundColor(for: style)
    let radius = FKIconViewRenderer.cornerRadius(for: style, side: configuration.layout.size.side)
    backgroundPlate.layer.cornerRadius = radius
    backgroundPlate.layer.cornerCurve = .continuous
    backgroundPlate.isHidden = style.isNone
  }

  private func updateAccessibility() {
    let a11y = configuration.accessibility
    if a11y.isDecorative {
      isAccessibilityElement = false
      accessibilityElementsHidden = true
      accessibilityLabel = nil
      accessibilityHint = nil
      return
    }
    isAccessibilityElement = true
    accessibilityElementsHidden = false
    accessibilityLabel = a11y.customLabel
    accessibilityHint = a11y.customHint
    accessibilityTraits = .image
  }
}
