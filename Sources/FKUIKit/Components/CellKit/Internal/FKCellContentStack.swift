import UIKit

/// Three-zone horizontal layout engine for display and settings rows (§11.5.1).
@MainActor
final class FKCellContentStack: UIView {
  let leadingSlot = UIView()
  let textStack = UIStackView()
  let trailingSlot = UIStackView()

  let titleLabel = UILabel()
  let subtitleLabel = UILabel()
  let detailLabel = UILabel()

  private var leadingWidthConstraint: NSLayoutConstraint?
  private var leadingSpacingConstraint: NSLayoutConstraint?
  private var accessoryViews: [UIView] = []
  private var appearance: FKCellAppearanceConfiguration = .default

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func applyAppearance(_ appearance: FKCellAppearanceConfiguration) {
    self.appearance = appearance
    refreshTypography()
  }

  func setLeadingContent(_ view: UIView?, width: CGFloat) {
    leadingSlot.subviews.forEach { $0.removeFromSuperview() }
    guard let view else {
      leadingWidthConstraint?.constant = 0
      leadingSlot.isHidden = true
      leadingSpacingConstraint?.constant = 0
      return
    }
    leadingSlot.isHidden = false
    view.translatesAutoresizingMaskIntoConstraints = false
    leadingSlot.addSubview(view)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: leadingSlot.topAnchor),
      view.leadingAnchor.constraint(equalTo: leadingSlot.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: leadingSlot.trailingAnchor),
      view.bottomAnchor.constraint(lessThanOrEqualTo: leadingSlot.bottomAnchor),
      view.centerYAnchor.constraint(equalTo: leadingSlot.centerYAnchor),
    ])
    leadingWidthConstraint?.constant = width
    leadingSpacingConstraint?.constant = width > 0 ? FKCellLayoutMetrics.iconColumnSpacing : 0
  }

  func setTitle(_ text: String?, numberOfLines: Int = 0, font: UIFont? = nil, color: UIColor? = nil) {
    titleLabel.text = text
    titleLabel.numberOfLines = numberOfLines
    titleLabel.isHidden = text?.isEmpty ?? true
    if let font { titleLabel.font = font }
    if let color { titleLabel.textColor = color }
  }

  func setSubtitle(_ text: String?, numberOfLines: Int = 0) {
    subtitleLabel.text = text
    subtitleLabel.numberOfLines = numberOfLines
    subtitleLabel.isHidden = text?.isEmpty ?? true
  }

  func setDetail(
    _ text: String?,
    numberOfLines: Int = 1,
    emphasis: FKCellValueEmphasis = .secondary
  ) {
    detailLabel.text = text
    detailLabel.numberOfLines = numberOfLines
    detailLabel.isHidden = text?.isEmpty ?? true
    detailLabel.textColor = emphasis == .secondary
      ? appearance.secondaryLabelColor.resolvedColor(with: traitCollection)
      : .label
    rebuildTrailingSlot()
  }

  func setAccessoryViews(_ views: [UIView], spacing: CGFloat = FKCellLayoutMetrics.trailingAccessorySpacing) {
    accessoryViews = views
    trailingSlot.spacing = spacing
    rebuildTrailingSlot()
  }

  /// Leading anchor for separator inset alignment (title leading).
  var separatorAlignmentAnchor: NSLayoutXAxisAnchor {
    titleLabel.leadingAnchor
  }

  private func rebuildTrailingSlot() {
    trailingSlot.arrangedSubviews.forEach {
      trailingSlot.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    if !detailLabel.isHidden {
      trailingSlot.addArrangedSubview(detailLabel)
    }
    accessoryViews.forEach { trailingSlot.addArrangedSubview($0) }
    trailingSlot.isHidden = trailingSlot.arrangedSubviews.isEmpty
  }

  private func commonInit() {
    translatesAutoresizingMaskIntoConstraints = false

    leadingSlot.translatesAutoresizingMaskIntoConstraints = false
    leadingSlot.setContentHuggingPriority(.required, for: .horizontal)
    leadingSlot.setContentCompressionResistancePriority(.required, for: .horizontal)

    textStack.axis = .vertical
    textStack.alignment = .fill
    textStack.spacing = FKCellLayoutMetrics.titleSubtitleSpacing
    textStack.translatesAutoresizingMaskIntoConstraints = false

    trailingSlot.axis = .horizontal
    trailingSlot.alignment = .center
    trailingSlot.spacing = FKCellLayoutMetrics.trailingAccessorySpacing
    trailingSlot.translatesAutoresizingMaskIntoConstraints = false
    trailingSlot.setContentHuggingPriority(.required, for: .horizontal)
    trailingSlot.setContentCompressionResistancePriority(.required, for: .horizontal)

    configureLabel(titleLabel, isTitle: true)
    configureLabel(subtitleLabel, isTitle: false)
    configureDetailLabel(detailLabel)

    textStack.addArrangedSubview(titleLabel)
    textStack.addArrangedSubview(subtitleLabel)
    subtitleLabel.isHidden = true

    detailLabel.isHidden = true
    trailingSlot.isHidden = true

    addSubview(leadingSlot)
    addSubview(textStack)
    addSubview(trailingSlot)

    leadingWidthConstraint = leadingSlot.widthAnchor.constraint(equalToConstant: 0)
    leadingWidthConstraint?.isActive = true

    NSLayoutConstraint.activate([
      leadingSlot.leadingAnchor.constraint(equalTo: leadingAnchor),
      leadingSlot.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
      leadingSlot.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
      leadingSlot.centerYAnchor.constraint(equalTo: centerYAnchor),

      {
        let spacing = textStack.leadingAnchor.constraint(
          equalTo: leadingSlot.trailingAnchor,
          constant: 0
        )
        leadingSpacingConstraint = spacing
        return spacing
      }(),
      textStack.topAnchor.constraint(equalTo: topAnchor),
      textStack.bottomAnchor.constraint(equalTo: bottomAnchor),
      textStack.trailingAnchor.constraint(
        lessThanOrEqualTo: trailingSlot.leadingAnchor,
        constant: -FKCellLayoutMetrics.trailingAccessorySpacing
      ),

      trailingSlot.trailingAnchor.constraint(equalTo: trailingAnchor),
      trailingSlot.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
      trailingSlot.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
      trailingSlot.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])

    titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    detailLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  private func configureLabel(_ label: UILabel, isTitle: Bool) {
    label.translatesAutoresizingMaskIntoConstraints = false
    label.adjustsFontForContentSizeCategory = true
    label.numberOfLines = 0
    label.lineBreakMode = .byWordWrapping
    label.setContentCompressionResistancePriority(isTitle ? .defaultHigh : .defaultLow, for: .vertical)
  }

  private func configureDetailLabel(_ label: UILabel) {
    label.translatesAutoresizingMaskIntoConstraints = false
    label.adjustsFontForContentSizeCategory = true
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingTail
    label.textAlignment = .natural
  }

  private func refreshTypography() {
    titleLabel.font = appearance.titleTextStyle.resolvedFont(compatibleWith: traitCollection)
    if titleLabel.textColor != appearance.linkColor && titleLabel.textColor != appearance.destructiveColor {
      titleLabel.textColor = .label
    }
    subtitleLabel.font = appearance.subtitleTextStyle.resolvedFont(compatibleWith: traitCollection)
    subtitleLabel.textColor = appearance.secondaryLabelColor.resolvedColor(with: traitCollection)
    detailLabel.font = appearance.detailTextStyle.resolvedFont(compatibleWith: traitCollection)
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory
      || traitCollection.layoutDirection != previousTraitCollection?.layoutDirection
    {
      refreshTypography()
    }
  }
}
