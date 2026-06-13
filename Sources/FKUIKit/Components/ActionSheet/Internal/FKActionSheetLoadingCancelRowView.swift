import UIKit

/// Standalone cancel row for the loading host (not embedded in `UITableView`).
@MainActor
final class FKActionSheetLoadingCancelRowView: UIView {
  private let titleLabel = UILabel()
  private var minimumHeightConstraint: NSLayoutConstraint?

  override init(frame: CGRect) {
    super.init(frame: frame)
    insetsLayoutMarginsFromSafeArea = false
    isAccessibilityElement = true
    accessibilityTraits = .button

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0
    addSubview(titleLabel)

    let minimumHeight = titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
    minimumHeightConstraint = minimumHeight

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: topAnchor),
      titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
      titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
      minimumHeight,
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(action: FKActionSheetAction, appearance: FKActionSheetAppearance) {
    minimumHeightConstraint?.constant = appearance.minimumRowHeight
    titleLabel.text = action.title
    titleLabel.font = appearance.resolvedActionTitleFont(isCancel: true)
    titleLabel.textColor = action.isEnabled ? appearance.cancelTitleColor : appearance.disabledTitleColor
    accessibilityLabel = action.accessibilityLabel ?? action.title
    accessibilityHint = action.accessibilityHint
  }
}
