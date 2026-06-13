import UIKit

/// Standard title/subtitle row with optional symbol, loading state, and selection accessory.
@MainActor
final class FKActionSheetActionCell: UITableViewCell {
  static let reuseIdentifier = "FKActionSheetActionCell"

  private enum Layout {
    static let horizontalPadding: CGFloat = 16
    static let selectionIndicatorSize: CGFloat = 24
    static let iconSize: CGFloat = 28
  }

  private enum SelectionAccessoryDisplayMode: Equatable {
    case hidden
    case check
    case radio(isSelected: Bool)
  }

  private let titleLabel = UILabel()
  private var iconView: UIImageView?
  private var subtitleLabel: UILabel?
  private var activityIndicator: UIActivityIndicatorView?
  private var selectionIndicatorImageView: UIImageView?

  private let textStack = UIStackView()
  private let rowStack = UIStackView()

  private var rowAlignment: FKActionSheetRowAlignment = .leading
  private var centerRowConstraints: [NSLayoutConstraint] = []
  private var leadingRowConstraints: [NSLayoutConstraint] = []
  private var minimumHeightConstraint: NSLayoutConstraint?
  private var selectionIndicatorTrailingConstraint: NSLayoutConstraint?
  private var selectionIndicatorCenterYConstraint: NSLayoutConstraint?
  private var iconSizeConstraints: [NSLayoutConstraint] = []
  private var selectionAccessoryDisplayMode = SelectionAccessoryDisplayMode.hidden

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .default
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    let selected = UIView()
    selected.translatesAutoresizingMaskIntoConstraints = false
    selectedBackgroundView = selected

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 0

    textStack.axis = .vertical
    textStack.spacing = 2
    textStack.addArrangedSubview(titleLabel)

    rowStack.axis = .horizontal
    rowStack.alignment = .center
    rowStack.distribution = .fill
    rowStack.spacing = 12
    rowStack.translatesAutoresizingMaskIntoConstraints = false
    rowStack.addArrangedSubview(textStack)
    contentView.addSubview(rowStack)

    minimumHeightConstraint = contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
    minimumHeightConstraint?.priority = .required

    centerRowConstraints = [
      rowStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
      rowStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
      rowStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      rowStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      rowStack.leadingAnchor.constraint(
        greaterThanOrEqualTo: contentView.leadingAnchor,
        constant: Layout.horizontalPadding
      ),
      rowStack.trailingAnchor.constraint(
        lessThanOrEqualTo: contentView.trailingAnchor,
        constant: -Layout.horizontalPadding
      ),
    ]

    leadingRowConstraints = [
      rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
      rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
      rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.horizontalPadding),
      rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.horizontalPadding),
    ]

    NSLayoutConstraint.activate(leadingRowConstraints + [minimumHeightConstraint!])
    textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(
    action: FKActionSheetAction,
    appearance: FKActionSheetAppearance,
    isCancelGroup: Bool,
    selectionIndicatorStyle: FKActionSheetSelectionIndicatorStyle,
    selectionModeActive: Bool,
    isRowInteractionEnabled: Bool = true
  ) {
    minimumHeightConstraint?.constant = appearance.minimumRowHeight
    let suppressesRowHighlight = selectionModeActive && !isCancelGroup
    if suppressesRowHighlight {
      selectionStyle = .none
      selectedBackgroundView = nil
    } else {
      selectionStyle = .default
      if selectedBackgroundView == nil {
        selectedBackgroundView = UIView()
      }
      selectedBackgroundView?.backgroundColor = appearance.rowHighlightColor
    }

    let isInteractionBlocked = !isRowInteractionEnabled
    let showsDisabledAppearance = !action.isEnabled || action.isLoading || isInteractionBlocked

    let titleFont = appearance.resolvedActionTitleFont(isCancel: isCancelGroup)
    titleLabel.text = action.title
    titleLabel.font = titleFont

    let highlightsTitle = selectionModeActive
      && action.isSelected
      && !showsDisabledAppearance
      && selectionIndicatorStyle.usesHighlightedTitle

    syncSubtitle(
      action.subtitle,
      appearance: appearance,
      textAlignment: resolvedTextAlignment(for: appearance.rowAlignment)
    )

    let titleColor = resolvedActionTitleColor(
      action: action,
      appearance: appearance,
      isCancelGroup: isCancelGroup,
      highlightsTitle: highlightsTitle,
      showsDisabledAppearance: showsDisabledAppearance
    )
    titleLabel.textColor = titleColor

    let showsIcon = action.image != nil
    if showsIcon, let image = action.image {
      let icon = ensureIconView()
      icon.image = image
      icon.tintColor = showsDisabledAppearance ? appearance.disabledTitleColor : appearance.iconTintColor
    } else {
      removeIconViewIfNeeded()
    }

    let showsActivity = action.isLoading
    if showsActivity {
      ensureActivityIndicator().startAnimating()
    } else {
      removeActivityIndicatorIfNeeded()
    }

    syncRowStackArrangedSubviews(showsIcon: showsIcon, showsActivity: showsActivity)
    updateRowAlignmentIfNeeded(appearance.rowAlignment)

    updateSelectionAccessoryState(
      action: action,
      appearance: appearance,
      isCancelGroup: isCancelGroup,
      indicatorStyle: selectionIndicatorStyle,
      selectionModeActive: selectionModeActive,
      titleColor: titleColor,
      showsDisabledAppearance: showsDisabledAppearance
    )

    isUserInteractionEnabled = isRowInteractionEnabled && !action.isLoading
    accessibilityLabel = action.accessibilityLabel ?? action.title
    if let hint = action.accessibilityHint {
      accessibilityHint = hint
    } else if action.style == .destructive {
      accessibilityHint = appearance.destructiveAccessibilityHint
    } else {
      accessibilityHint = nil
    }
    var traits: UIAccessibilityTraits = .button
    if action.isSelected { traits.insert(.selected) }
    if action.isLoading { traits.insert(.updatesFrequently) }
    accessibilityTraits = traits
  }

  private func syncSubtitle(
    _ subtitle: String?,
    appearance: FKActionSheetAppearance,
    textAlignment: NSTextAlignment
  ) {
    if let subtitle, !subtitle.isEmpty {
      let label = ensureSubtitleLabel()
      label.font = appearance.resolvedActionSubtitleFont()
      label.textColor = appearance.subtitleColor
      label.text = subtitle
      label.textAlignment = textAlignment
      if !textStack.arrangedSubviews.contains(label) {
        textStack.addArrangedSubview(label)
      }
    } else {
      removeSubtitleLabelIfNeeded()
    }
  }

  private func syncRowStackArrangedSubviews(showsIcon: Bool, showsActivity: Bool) {
    var desired: [UIView] = []
    if showsIcon, let iconView {
      desired.append(iconView)
    }
    desired.append(textStack)
    if showsActivity, let activityIndicator {
      desired.append(activityIndicator)
    }

    guard rowStack.arrangedSubviews.map(ObjectIdentifier.init) != desired.map(ObjectIdentifier.init) else {
      return
    }

    rowStack.arrangedSubviews.forEach { view in
      rowStack.removeArrangedSubview(view)
      if view !== textStack {
        view.removeFromSuperview()
      }
    }

    desired.forEach { view in
      if view.superview == nil {
        rowStack.addArrangedSubview(view)
      } else if !rowStack.arrangedSubviews.contains(view) {
        rowStack.addArrangedSubview(view)
      }
    }

    iconView?.setContentHuggingPriority(.required, for: .horizontal)
    iconView?.setContentCompressionResistancePriority(.required, for: .horizontal)
    activityIndicator?.setContentHuggingPriority(.required, for: .horizontal)
    activityIndicator?.setContentCompressionResistancePriority(.required, for: .horizontal)
    textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
    textStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
  }

  private func updateRowAlignmentIfNeeded(_ alignment: FKActionSheetRowAlignment) {
    guard alignment != rowAlignment else { return }
    rowAlignment = alignment

    NSLayoutConstraint.deactivate(centerRowConstraints + leadingRowConstraints)

    let textAlignment = resolvedTextAlignment(for: alignment)
    titleLabel.textAlignment = textAlignment
    subtitleLabel?.textAlignment = textAlignment

    switch alignment {
    case .center:
      textStack.alignment = .center
      rowStack.alignment = .center
      rowStack.spacing = 10
      NSLayoutConstraint.activate(centerRowConstraints)
    case .leading:
      textStack.alignment = .leading
      rowStack.alignment = .center
      rowStack.spacing = 12
      rowStack.distribution = .fill
      NSLayoutConstraint.activate(leadingRowConstraints)
    }
  }

  private func resolvedTextAlignment(for alignment: FKActionSheetRowAlignment) -> NSTextAlignment {
    alignment == .center ? .center : .natural
  }

  private func ensureIconView() -> UIImageView {
    if let iconView {
      return iconView
    }
    let view = UIImageView()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.contentMode = .scaleAspectFit
    view.setContentHuggingPriority(.required, for: .horizontal)
    view.setContentCompressionResistancePriority(.required, for: .horizontal)
    iconSizeConstraints = [
      view.widthAnchor.constraint(equalToConstant: Layout.iconSize),
      view.heightAnchor.constraint(equalToConstant: Layout.iconSize),
    ]
    NSLayoutConstraint.activate(iconSizeConstraints)
    iconView = view
    return view
  }

  private func removeIconViewIfNeeded() {
    guard let iconView else { return }
    rowStack.removeArrangedSubview(iconView)
    iconView.removeFromSuperview()
    NSLayoutConstraint.deactivate(iconSizeConstraints)
    iconSizeConstraints = []
    iconView.image = nil
    self.iconView = nil
  }

  private func ensureSubtitleLabel() -> UILabel {
    if let subtitleLabel {
      return subtitleLabel
    }
    let label = UILabel()
    label.translatesAutoresizingMaskIntoConstraints = false
    label.numberOfLines = 0
    subtitleLabel = label
    return label
  }

  private func removeSubtitleLabelIfNeeded() {
    guard let subtitleLabel else { return }
    textStack.removeArrangedSubview(subtitleLabel)
    subtitleLabel.removeFromSuperview()
    subtitleLabel.text = nil
    self.subtitleLabel = nil
  }

  private func ensureActivityIndicator() -> UIActivityIndicatorView {
    if let activityIndicator {
      return activityIndicator
    }
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.hidesWhenStopped = true
    indicator.setContentHuggingPriority(.required, for: .horizontal)
    indicator.setContentCompressionResistancePriority(.required, for: .horizontal)
    activityIndicator = indicator
    return indicator
  }

  private func removeActivityIndicatorIfNeeded() {
    guard let activityIndicator else { return }
    activityIndicator.stopAnimating()
    rowStack.removeArrangedSubview(activityIndicator)
    activityIndicator.removeFromSuperview()
    self.activityIndicator = nil
  }

  private func updateSelectionAccessoryState(
    action: FKActionSheetAction,
    appearance: FKActionSheetAppearance,
    isCancelGroup: Bool,
    indicatorStyle: FKActionSheetSelectionIndicatorStyle,
    selectionModeActive: Bool,
    titleColor: UIColor,
    showsDisabledAppearance: Bool
  ) {
    selectionAccessoryDisplayMode = selectionAccessoryMode(
      action: action,
      isCancelGroup: isCancelGroup,
      indicatorStyle: indicatorStyle,
      selectionModeActive: selectionModeActive,
      showsDisabledAppearance: showsDisabledAppearance
    )
    let tintColor = resolvedSelectionIndicatorTint(
      action: action,
      appearance: appearance,
      titleColor: titleColor
    )
    accessoryView = nil

    if showsSelectionAccessoryIcon {
      let imageView = ensureSelectionIndicatorImageView()
      applySelectionIndicator(to: imageView, mode: selectionAccessoryDisplayMode, tintColor: tintColor)
      imageView.isHidden = false
      selectionIndicatorTrailingConstraint?.isActive = true
      selectionIndicatorCenterYConstraint?.isActive = true
      contentView.bringSubviewToFront(imageView)
    } else {
      removeSelectionIndicatorIfNeeded()
    }
  }

  private func ensureSelectionIndicatorImageView() -> UIImageView {
    if let selectionIndicatorImageView {
      return selectionIndicatorImageView
    }
    let imageView = UIImageView()
    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.contentMode = .scaleAspectFit
    imageView.isUserInteractionEnabled = false
    imageView.setContentHuggingPriority(.required, for: .horizontal)
    imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    contentView.addSubview(imageView)

    selectionIndicatorTrailingConstraint = imageView.trailingAnchor.constraint(
      equalTo: contentView.trailingAnchor,
      constant: -Layout.horizontalPadding
    )
    selectionIndicatorCenterYConstraint = imageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)

    NSLayoutConstraint.activate([
      imageView.widthAnchor.constraint(equalToConstant: Layout.selectionIndicatorSize),
      imageView.heightAnchor.constraint(equalToConstant: Layout.selectionIndicatorSize),
      selectionIndicatorTrailingConstraint!,
      selectionIndicatorCenterYConstraint!,
    ])

    selectionIndicatorImageView = imageView
    return imageView
  }

  private func removeSelectionIndicatorIfNeeded() {
    guard let selectionIndicatorImageView else { return }
    selectionIndicatorTrailingConstraint?.isActive = false
    selectionIndicatorCenterYConstraint?.isActive = false
    selectionIndicatorImageView.image = nil
    selectionIndicatorImageView.isHidden = true
    selectionIndicatorImageView.removeFromSuperview()
    self.selectionIndicatorImageView = nil
    selectionIndicatorTrailingConstraint = nil
    selectionIndicatorCenterYConstraint = nil
  }

  private func applySelectionIndicator(
    to imageView: UIImageView,
    mode: SelectionAccessoryDisplayMode,
    tintColor: UIColor
  ) {
    switch mode {
    case .hidden:
      imageView.image = nil
    case .check:
      imageView.image = Self.selectionSymbolImage(named: .check)
    case .radio(let isSelected):
      imageView.image = Self.selectionSymbolImage(
        named: isSelected ? .radioChecked : .radioUnchecked
      )
    }
    imageView.tintColor = tintColor
  }

  /// Matches the title label color so icons stay in sync with highlighted vs non-highlighted rows.
  private func resolvedActionTitleColor(
    action: FKActionSheetAction,
    appearance: FKActionSheetAppearance,
    isCancelGroup: Bool,
    highlightsTitle: Bool,
    showsDisabledAppearance: Bool
  ) -> UIColor {
    if showsDisabledAppearance { return appearance.disabledTitleColor }
    if isCancelGroup { return appearance.cancelTitleColor }
    var color: UIColor = {
      switch action.style {
      case .destructive: return appearance.destructiveTitleColor
      case .default, .cancel: return appearance.actionTitleColor
      }
    }()
    if highlightsTitle {
      color = appearance.selectedTitleColor
    }
    return color
  }

  private func resolvedSelectionIndicatorTint(
    action: FKActionSheetAction,
    appearance: FKActionSheetAppearance,
    titleColor: UIColor
  ) -> UIColor {
    if action.isSelected {
      return titleColor
    }
    return appearance.selectionIndicatorTintColor
  }

  private func selectionAccessoryMode(
    action: FKActionSheetAction,
    isCancelGroup: Bool,
    indicatorStyle: FKActionSheetSelectionIndicatorStyle,
    selectionModeActive: Bool,
    showsDisabledAppearance: Bool
  ) -> SelectionAccessoryDisplayMode {
    guard selectionModeActive, !isCancelGroup, !showsDisabledAppearance else { return .hidden }
    if indicatorStyle.usesCheck {
      return action.isSelected ? .check : .hidden
    }
    if indicatorStyle.usesRadio {
      return .radio(isSelected: action.isSelected)
    }
    return .hidden
  }

  private var showsSelectionAccessoryIcon: Bool {
    selectionAccessoryDisplayMode != .hidden
  }

  private static func selectionSymbolImage(named name: FKUIKitResourceBundle.SymbolName) -> UIImage? {
    FKUIKitResourceBundle.symbol(named: name, configuration: nil)?
      .withRenderingMode(.alwaysTemplate)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    accessoryView = nil
    selectionAccessoryDisplayMode = .hidden
    removeSelectionIndicatorIfNeeded()
    removeIconViewIfNeeded()
    removeSubtitleLabelIfNeeded()
    removeActivityIndicatorIfNeeded()
    syncRowStackArrangedSubviews(showsIcon: false, showsActivity: false)
  }
}
