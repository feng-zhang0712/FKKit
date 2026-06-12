import UIKit

/// Three-zone horizontal layout engine for display and settings rows (§11.5.1).
@MainActor
final class FKCellContentStack: UIView {
  let leadingSlot = UIView()
  let titleLabel = UILabel()
  let subtitleLabel = UILabel()
  let detailLabel = UILabel()

  private var trailingStackStorage: UIStackView?
  private var trailingItemConstraints: [NSLayoutConstraint] = []
  private var trailingGuideLeadingConstraint: NSLayoutConstraint?
  private let trailingLeadingGuide = UILayoutGuide()

  private var leadingWidthConstraint: NSLayoutConstraint?
  private var leadingItemConstraints: [NSLayoutConstraint] = []
  private var leadingSpacingConstraint: NSLayoutConstraint?
  private var titleCenterYConstraint: NSLayoutConstraint?
  private var titleTopConstraint: NSLayoutConstraint?
  private var subtitleTopConstraint: NSLayoutConstraint?
  private var subtitleBottomConstraint: NSLayoutConstraint?
  private var accessoryViews: [UIView] = []
  private var mountedTrailingViews: [UIView] = []
  private var trailingSpacing = FKCellLayoutMetrics.trailingAccessorySpacing
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
    NSLayoutConstraint.deactivate(leadingItemConstraints)
    leadingItemConstraints = []
    leadingSlot.subviews.forEach { $0.removeFromSuperview() }
    leadingWidthConstraint?.constant = width

    guard let view, width > 0 else {
      leadingSlot.isHidden = true
      leadingSpacingConstraint?.constant = 0
      return
    }

    leadingSlot.isHidden = false
    leadingSpacingConstraint?.constant = FKCellLayoutMetrics.iconColumnSpacing
    view.translatesAutoresizingMaskIntoConstraints = false
    leadingSlot.addSubview(view)
    leadingItemConstraints = [
      view.centerXAnchor.constraint(equalTo: leadingSlot.centerXAnchor),
      view.centerYAnchor.constraint(equalTo: leadingSlot.centerYAnchor),
      view.topAnchor.constraint(greaterThanOrEqualTo: leadingSlot.topAnchor),
      view.bottomAnchor.constraint(lessThanOrEqualTo: leadingSlot.bottomAnchor),
    ]
    NSLayoutConstraint.activate(leadingItemConstraints)
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
    updateTextLayoutConstraints()
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
    rebuildTrailingContent()
  }

  func setAccessoryViews(_ views: [UIView], spacing: CGFloat = FKCellLayoutMetrics.trailingAccessorySpacing) {
    accessoryViews = views
    trailingSpacing = spacing
    rebuildTrailingContent()
  }

  /// Leading anchor for separator inset alignment (title leading).
  var separatorAlignmentAnchor: NSLayoutXAxisAnchor {
    titleLabel.leadingAnchor
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard !isHidden, isUserInteractionEnabled, alpha >= 0.01, bounds.contains(point) else { return nil }
    for subview in subviews.reversed() {
      let converted = convert(point, to: subview)
      if let hit = subview.hitTest(converted, with: event) { return hit }
    }
    return nil
  }

  private func rebuildTrailingContent() {
    trailingStackStorage?.removeFromSuperview()
    trailingStackStorage = nil

    for view in mountedTrailingViews where view.superview === self {
      view.removeFromSuperview()
    }
    mountedTrailingViews = []

    NSLayoutConstraint.deactivate(trailingItemConstraints)
    trailingItemConstraints = []

    var items: [UIView] = []
    if !detailLabel.isHidden { items.append(detailLabel) }
    items.append(contentsOf: accessoryViews)

    guard !items.isEmpty else {
      attachTrailingGuide(to: nil)
      return
    }

    items.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }

    if items.count == 1 {
      let view = items[0]
      addSubview(view)
      trailingItemConstraints = [
        view.trailingAnchor.constraint(equalTo: trailingAnchor),
        view.centerYAnchor.constraint(equalTo: centerYAnchor),
        view.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
        view.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
      ]
      attachTrailingGuide(to: view)
    } else {
      let stack = UIStackView(arrangedSubviews: items)
      stack.axis = .horizontal
      stack.alignment = .center
      stack.spacing = trailingSpacing
      stack.translatesAutoresizingMaskIntoConstraints = false
      stack.setContentHuggingPriority(.required, for: .horizontal)
      stack.setContentCompressionResistancePriority(.required, for: .horizontal)
      addSubview(stack)
      trailingStackStorage = stack
      trailingItemConstraints = [
        stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
        stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
      ]
      attachTrailingGuide(to: stack)
    }

    NSLayoutConstraint.activate(trailingItemConstraints)
    mountedTrailingViews = items
  }

  private func attachTrailingGuide(to view: UIView?) {
    trailingGuideLeadingConstraint?.isActive = false
    if let view {
      trailingGuideLeadingConstraint = trailingLeadingGuide.leadingAnchor.constraint(
        equalTo: view.leadingAnchor
      )
    } else {
      trailingGuideLeadingConstraint = trailingLeadingGuide.leadingAnchor.constraint(
        equalTo: trailingLeadingGuide.trailingAnchor
      )
    }
    trailingGuideLeadingConstraint?.isActive = true
  }

  private func commonInit() {
    translatesAutoresizingMaskIntoConstraints = false

    leadingSlot.translatesAutoresizingMaskIntoConstraints = false
    leadingSlot.setContentHuggingPriority(.required, for: .horizontal)
    leadingSlot.setContentCompressionResistancePriority(.required, for: .horizontal)

    configureLabel(titleLabel, isTitle: true)
    configureLabel(subtitleLabel, isTitle: false)
    configureDetailLabel(detailLabel)

    subtitleLabel.isHidden = true
    detailLabel.isHidden = true

    addSubview(leadingSlot)
    addSubview(titleLabel)
    addSubview(subtitleLabel)
    addLayoutGuide(trailingLeadingGuide)

    leadingWidthConstraint = leadingSlot.widthAnchor.constraint(equalToConstant: 0)
    leadingWidthConstraint?.isActive = true

    let textLeading = titleLabel.leadingAnchor.constraint(
      equalTo: leadingSlot.trailingAnchor,
      constant: 0
    )
    leadingSpacingConstraint = textLeading

    titleCenterYConstraint = titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
    titleTopConstraint = titleLabel.topAnchor.constraint(equalTo: topAnchor)
    subtitleTopConstraint = subtitleLabel.topAnchor.constraint(
      equalTo: titleLabel.bottomAnchor,
      constant: FKCellLayoutMetrics.titleSubtitleSpacing
    )
    subtitleBottomConstraint = subtitleLabel.bottomAnchor.constraint(equalTo: bottomAnchor)

    trailingGuideLeadingConstraint = trailingLeadingGuide.leadingAnchor.constraint(
      equalTo: trailingLeadingGuide.trailingAnchor
    )

    NSLayoutConstraint.activate([
      leadingSlot.leadingAnchor.constraint(equalTo: leadingAnchor),
      leadingSlot.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
      leadingSlot.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
      leadingSlot.centerYAnchor.constraint(equalTo: centerYAnchor),

      textLeading,
      titleLabel.trailingAnchor.constraint(
        lessThanOrEqualTo: trailingLeadingGuide.leadingAnchor,
        constant: -FKCellLayoutMetrics.trailingAccessorySpacing
      ),
      subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      subtitleLabel.trailingAnchor.constraint(
        lessThanOrEqualTo: trailingLeadingGuide.leadingAnchor,
        constant: -FKCellLayoutMetrics.trailingAccessorySpacing
      ),

      trailingLeadingGuide.trailingAnchor.constraint(equalTo: trailingAnchor),
      trailingGuideLeadingConstraint!,
    ])

    updateTextLayoutConstraints()

    titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    detailLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    detailLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
  }

  private func updateTextLayoutConstraints() {
    let hasSubtitle = !subtitleLabel.isHidden
    titleCenterYConstraint?.isActive = !hasSubtitle
    titleTopConstraint?.isActive = hasSubtitle
    subtitleTopConstraint?.isActive = hasSubtitle
    subtitleBottomConstraint?.isActive = hasSubtitle
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
