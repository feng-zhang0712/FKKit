import UIKit

/// Toggle switch row that updates in place without dismissing the sheet.
@MainActor
final class FKActionSheetToggleCell: UITableViewCell {
  static let defaultReuseIdentifier = "FKActionSheetToggleRow"

  private let titleLabel = UILabel()
  private let toggleSwitch = UISwitch()
  private var onValueChanged: ((Bool) -> Void)?

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    selectionStyle = .none
    backgroundColor = .clear
    contentView.backgroundColor = .clear

    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.numberOfLines = 0

    toggleSwitch.translatesAutoresizingMaskIntoConstraints = false
    toggleSwitch.addTarget(self, action: #selector(switchChanged), for: .valueChanged)

    let stack = UIStackView(arrangedSubviews: [titleLabel, toggleSwitch])
    stack.axis = .horizontal
    stack.alignment = .center
    stack.spacing = 12
    stack.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: 10),
      stack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -10),
      stack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(
    action: FKActionSheetAction,
    toggle: FKActionSheetToggleRow,
    appearance: FKActionSheetAppearance,
    onValueChanged: @escaping (Bool) -> Void
  ) {
    self.onValueChanged = onValueChanged
    titleLabel.font = appearance.resolvedActionTitleFont(isCancel: false)
    titleLabel.textColor = action.isEnabled ? appearance.actionTitleColor : appearance.disabledTitleColor
    titleLabel.text = action.title
    titleLabel.adjustsFontForContentSizeCategory = true

    toggleSwitch.isOn = toggle.isOn
    toggleSwitch.isEnabled = action.isEnabled
    isUserInteractionEnabled = action.isEnabled

    accessibilityLabel = action.accessibilityLabel ?? action.title
    accessibilityHint = action.accessibilityHint
    accessibilityTraits = .staticText
  }

  /// Updates the switch value without reconfiguring the whole cell.
  ///
  /// Skips `UISwitch` updates when the value is unchanged so in-flight switch animations are not interrupted.
  func setToggleOn(_ isOn: Bool, animated: Bool) {
    guard toggleSwitch.isOn != isOn else { return }
    toggleSwitch.setOn(isOn, animated: animated)
  }

  @objc private func switchChanged() {
    onValueChanged?(toggleSwitch.isOn)
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    onValueChanged = nil
  }
}
