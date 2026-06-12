import UIKit

/// Title, subtitle, gradient scrim, and CTA overlay for an image banner page.
@MainActor
final class FKImageBannerOverlayView: UIView {
  private let gradientLayer = CAGradientLayer()
  private var textStack: UIStackView?
  private var titleLabel: UILabel?
  private var subtitleLabel: UILabel?
  private var ctaButton: FKButton?
  private var textStackBottomConstraint: NSLayoutConstraint?

  var configuration: FKImageBannerConfiguration = .init() {
    didSet { applyConfiguration() }
  }

  var slide: FKImageBannerSlide? {
    didSet { applySlide() }
  }

  var onCTATap: (() -> Void)?

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer.frame = bounds
  }

  private func commonInit() {
    isUserInteractionEnabled = true
    layer.addSublayer(gradientLayer)
    applyConfiguration()
  }

  @objc private func handleCTATap() {
    onCTATap?()
  }

  private func applyConfiguration() {
    let gradient = configuration.gradientOverlay
    gradientLayer.colors = gradient.colors.map(\.cgColor)
    gradientLayer.locations = gradient.locations.map { NSNumber(value: Double($0)) }
    titleLabel?.numberOfLines = configuration.maximumTitleLines
    subtitleLabel?.numberOfLines = configuration.maximumSubtitleLines
  }

  private func applySlide() {
    guard let slide else {
      removeTextStackIfNeeded()
      removeCTAButtonIfNeeded()
      gradientLayer.isHidden = true
      isAccessibilityElement = false
      return
    }

    let visibility = slide.overlayStyle?.visibility ?? configuration.overlayVisibility
    let isVisible = visibility == .always
    let isA11yOnly = visibility == .accessibilityOnly
    gradientLayer.isHidden = !isVisible && !isA11yOnly

    let hasTitle = slide.title?.isEmpty == false
    let hasSubtitle = slide.subtitle?.isEmpty == false
    let ctaTitle = slide.overlayStyle?.ctaTitle ?? configuration.defaultCTATitle
    let shouldShowCTA = isVisible && ctaTitle?.isEmpty == false
    let needsTextStack = (isVisible || isA11yOnly) && (hasTitle || hasSubtitle)

    if needsTextStack {
      let labels = installTextStackIfNeeded()
      labels.title.text = slide.title
      labels.subtitle.text = slide.subtitle
      labels.subtitle.isHidden = slide.subtitle?.isEmpty != false
      labels.stack.isHidden = !isVisible
      labels.title.isHidden = labels.title.text?.isEmpty != false
      labels.subtitle.isHidden = labels.subtitle.isHidden || labels.subtitle.text?.isEmpty != false
      labels.title.isAccessibilityElement = isVisible || isA11yOnly
      labels.subtitle.isAccessibilityElement = (isVisible || isA11yOnly) && !labels.subtitle.isHidden
    } else {
      removeTextStackIfNeeded()
    }

    if shouldShowCTA, let ctaTitle {
      let button = installCTAButtonIfNeeded()
      button.setTitle(.init(text: ctaTitle, color: .label), for: .normal)
      button.accessibilityLabel = ctaTitle
      button.isAccessibilityElement = true
    } else {
      removeCTAButtonIfNeeded()
    }

    isAccessibilityElement = false
  }

  private func installTextStackIfNeeded() -> (stack: UIStackView, title: UILabel, subtitle: UILabel) {
    if let textStack, let titleLabel, let subtitleLabel {
      updateTextStackBottomAnchor()
      return (textStack, titleLabel, subtitleLabel)
    }

    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 4
    stack.alignment = .leading
    stack.translatesAutoresizingMaskIntoConstraints = false

    let title = UILabel()
    title.font = .preferredFont(forTextStyle: .headline)
    title.textColor = .white
    title.numberOfLines = configuration.maximumTitleLines
    title.adjustsFontForContentSizeCategory = true

    let subtitle = UILabel()
    subtitle.font = .preferredFont(forTextStyle: .subheadline)
    subtitle.textColor = UIColor.white.withAlphaComponent(0.85)
    subtitle.numberOfLines = configuration.maximumSubtitleLines
    subtitle.adjustsFontForContentSizeCategory = true

    stack.addArrangedSubview(title)
    stack.addArrangedSubview(subtitle)
    addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
    ])

    textStack = stack
    titleLabel = title
    subtitleLabel = subtitle
    updateTextStackBottomAnchor()
    return (stack, title, subtitle)
  }

  private func removeTextStackIfNeeded() {
    guard textStack != nil else { return }
    textStack?.removeFromSuperview()
    textStack = nil
    titleLabel = nil
    subtitleLabel = nil
    textStackBottomConstraint = nil
  }

  private func installCTAButtonIfNeeded() -> FKButton {
    if let ctaButton {
      updateTextStackBottomAnchor()
      return ctaButton
    }

    let button = FKButton()
    button.translatesAutoresizingMaskIntoConstraints = false
    var appearance = FKButtonAppearance.filled(
      backgroundColor: .white,
      cornerStyle: .init(corner: .capsule)
    )
    appearance.contentInsets = .init(top: 6, leading: 12, bottom: 6, trailing: 12)
    button.setAppearances(.init(normal: appearance))
    button.minimumTouchTargetSize = CGSize(width: 44, height: 44)
    button.addTarget(self, action: #selector(handleCTATap), for: .touchUpInside)
    addSubview(button)

    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      button.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
    ])

    ctaButton = button
    updateTextStackBottomAnchor()
    return button
  }

  private func removeCTAButtonIfNeeded() {
    guard ctaButton != nil else { return }
    ctaButton?.removeFromSuperview()
    ctaButton = nil
    updateTextStackBottomAnchor()
  }

  private func updateTextStackBottomAnchor() {
    textStackBottomConstraint?.isActive = false
    guard let textStack else { return }
    if let ctaButton {
      textStackBottomConstraint = textStack.bottomAnchor.constraint(equalTo: ctaButton.topAnchor, constant: -8)
    } else {
      textStackBottomConstraint = textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
    }
    textStackBottomConstraint?.isActive = true
  }

  func resetForReuse() {
    slide = nil
    onCTATap = nil
    removeTextStackIfNeeded()
    removeCTAButtonIfNeeded()
    gradientLayer.isHidden = true
  }
}
