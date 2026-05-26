import UIKit

/// Standard title/subtitle row with optional symbol, loading state, and selection accessory.
@MainActor
final class FKActionSheetActionCell: UITableViewCell {
  static let reuseIdentifier = "FKActionSheetActionCell"

  private enum Layout {
    static let horizontalPadding: CGFloat = 16
  }

  private let iconView = UIImageView()
  private let titleLabel = UILabel()
  private let subtitleLabel = UILabel()
  private let activityIndicator = UIActivityIndicatorView(style: .medium)
  private let rowContainer = UIView()
  private let selectionIndicator = FKActionSheetSelectionIndicatorView()

  private var centerRowStack: UIStackView?
  private var leadingRowStack: UIStackView?
  private var minimumHeightConstraint: NSLayoutConstraint?
  private var selectionIndicatorTrailingConstraint: NSLayoutConstraint?
  private var selectionIndicatorCenterYConstraint: NSLayoutConstraint?
  private var selectionAccessoryDisplayMode = FKActionSheetSelectionIndicatorView.DisplayMode.hidden

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .default
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    let selected = UIView()
    selected.translatesAutoresizingMaskIntoConstraints = false
    selectedBackgroundView = selected

    iconView.translatesAutoresizingMaskIntoConstraints = false
    iconView.contentMode = .scaleAspectFit
    iconView.setContentHuggingPriority(.required, for: .horizontal)
    iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 0

    subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
    subtitleLabel.numberOfLines = 0

    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    activityIndicator.hidesWhenStopped = true

    rowContainer.translatesAutoresizingMaskIntoConstraints = false
    selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
    selectionIndicator.isUserInteractionEnabled = false
    contentView.addSubview(rowContainer)
    rowContainer.addSubview(selectionIndicator)

    minimumHeightConstraint = rowContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
    minimumHeightConstraint?.priority = .required

    selectionIndicatorTrailingConstraint = selectionIndicator.trailingAnchor.constraint(
      equalTo: rowContainer.trailingAnchor,
      constant: -Layout.horizontalPadding
    )
    selectionIndicatorCenterYConstraint = selectionIndicator.centerYAnchor.constraint(
      equalTo: rowContainer.centerYAnchor
    )

    NSLayoutConstraint.activate([
      rowContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
      rowContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      rowContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      rowContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
      minimumHeightConstraint!,
      iconView.widthAnchor.constraint(equalToConstant: 28),
      iconView.heightAnchor.constraint(equalToConstant: 28),
    ])
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

    let highlightsTitle = selectionModeActive
      && action.isSelected
      && !showsDisabledAppearance
      && selectionIndicatorStyle.usesHighlightedTitle
    titleLabel.font = titleFont

    if let subtitle = action.subtitle, !subtitle.isEmpty {
      subtitleLabel.isHidden = false
      subtitleLabel.font = appearance.resolvedActionSubtitleFont()
      subtitleLabel.textColor = appearance.subtitleColor
      subtitleLabel.text = subtitle
    } else {
      subtitleLabel.isHidden = true
      subtitleLabel.text = nil
    }

    let titleColor = resolvedActionTitleColor(
      action: action,
      appearance: appearance,
      isCancelGroup: isCancelGroup,
      highlightsTitle: highlightsTitle,
      showsDisabledAppearance: showsDisabledAppearance
    )
    titleLabel.textColor = titleColor

    if let image = action.image {
      iconView.isHidden = false
      iconView.image = image
      iconView.tintColor = showsDisabledAppearance ? appearance.disabledTitleColor : appearance.iconTintColor
    } else {
      iconView.isHidden = true
      iconView.image = nil
    }

    if action.isLoading {
      activityIndicator.startAnimating()
    } else {
      activityIndicator.stopAnimating()
    }

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

    rebuildRowStack(alignment: appearance.rowAlignment)
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
    selectionIndicator.apply(mode: selectionAccessoryDisplayMode, tintColor: tintColor)
    accessoryView = nil

    let showsIcon = showsSelectionAccessoryIcon
    selectionIndicator.isHidden = !showsIcon
    selectionIndicatorTrailingConstraint?.isActive = showsIcon
    selectionIndicatorCenterYConstraint?.isActive = showsIcon
    if showsIcon {
      rowContainer.bringSubviewToFront(selectionIndicator)
    }
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
  ) -> FKActionSheetSelectionIndicatorView.DisplayMode {
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
    selectionAccessoryDisplayMode != .hidden && !selectionIndicator.isHidden
  }

  private func rebuildRowStack(alignment: FKActionSheetRowAlignment) {
    centerRowStack?.removeFromSuperview()
    leadingRowStack?.removeFromSuperview()
    centerRowStack = nil
    leadingRowStack = nil

    let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
    textStack.axis = .vertical
    textStack.spacing = 2

    let horizontalPadding = Layout.horizontalPadding

    switch alignment {
    case .center:
      textStack.alignment = .center
      titleLabel.textAlignment = .center
      subtitleLabel.textAlignment = .center
      let stack = UIStackView(arrangedSubviews: [iconView, textStack, activityIndicator])
      stack.axis = .horizontal
      stack.alignment = .center
      stack.spacing = 10
      stack.translatesAutoresizingMaskIntoConstraints = false
      rowContainer.addSubview(stack)
      NSLayoutConstraint.activate([
        stack.topAnchor.constraint(greaterThanOrEqualTo: rowContainer.topAnchor, constant: 10),
        stack.bottomAnchor.constraint(lessThanOrEqualTo: rowContainer.bottomAnchor, constant: -10),
        stack.centerYAnchor.constraint(equalTo: rowContainer.centerYAnchor),
        stack.centerXAnchor.constraint(equalTo: rowContainer.centerXAnchor),
        stack.leadingAnchor.constraint(greaterThanOrEqualTo: rowContainer.leadingAnchor, constant: horizontalPadding),
        stack.trailingAnchor.constraint(lessThanOrEqualTo: rowContainer.trailingAnchor, constant: -horizontalPadding),
      ])
      centerRowStack = stack
    case .leading:
      textStack.alignment = .leading
      titleLabel.textAlignment = .natural
      subtitleLabel.textAlignment = .natural
      let stack = UIStackView(arrangedSubviews: [iconView, textStack, UIView(), activityIndicator])
      stack.axis = .horizontal
      stack.alignment = .center
      stack.spacing = 12
      stack.translatesAutoresizingMaskIntoConstraints = false
      rowContainer.addSubview(stack)
      NSLayoutConstraint.activate([
        stack.topAnchor.constraint(equalTo: rowContainer.topAnchor, constant: 10),
        stack.bottomAnchor.constraint(equalTo: rowContainer.bottomAnchor, constant: -10),
        stack.leadingAnchor.constraint(equalTo: rowContainer.leadingAnchor, constant: horizontalPadding),
        stack.trailingAnchor.constraint(equalTo: rowContainer.trailingAnchor, constant: -horizontalPadding),
      ])
      leadingRowStack = stack
    }

    if showsSelectionAccessoryIcon {
      rowContainer.bringSubviewToFront(selectionIndicator)
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    iconView.image = nil
    accessoryView = nil
    selectionAccessoryDisplayMode = .hidden
    selectionIndicator.apply(mode: .hidden, tintColor: .label)
    selectionIndicator.isHidden = true
    selectionIndicatorTrailingConstraint?.isActive = false
    selectionIndicatorCenterYConstraint?.isActive = false
    activityIndicator.stopAnimating()
    subtitleLabel.isHidden = true
    centerRowStack?.removeFromSuperview()
    leadingRowStack?.removeFromSuperview()
    centerRowStack = nil
    leadingRowStack = nil
  }
}
