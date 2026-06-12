import UIKit

/// Reusable centered title/message header for the action sheet table.
@MainActor
final class FKActionSheetTextHeaderView: UIView {
  private let stack = UIStackView()
  private var titleLabel: UILabel?
  private var messageLabel: UILabel?

  override init(frame: CGRect) {
    super.init(frame: frame)
    insetsLayoutMarginsFromSafeArea = false
    isAccessibilityElement = true
    accessibilityTraits = .header

    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 4
    stack.translatesAutoresizingMaskIntoConstraints = false
    addSubview(stack)

    NSLayoutConstraint.activate([
      stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
      stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
      stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
      stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(header: FKActionSheetHeader, appearance: FKActionSheetAppearance) {
    var accessibilityParts: [String] = []

    if let title = header.title, !title.isEmpty {
      let label = ensureTitleLabel()
      label.font = appearance.resolvedHeaderTitleFont()
      label.textColor = appearance.headerTitleColor
      label.text = title
      if !stack.arrangedSubviews.contains(label) {
        stack.insertArrangedSubview(label, at: 0)
      }
      accessibilityParts.append(title)
    } else {
      removeTitleLabelIfNeeded()
    }

    if let message = header.message, !message.isEmpty {
      let label = ensureMessageLabel()
      label.font = appearance.resolvedHeaderMessageFont()
      label.textColor = appearance.headerMessageColor
      label.text = message
      if !stack.arrangedSubviews.contains(label) {
        stack.addArrangedSubview(label)
      }
      accessibilityParts.append(message)
    } else {
      removeMessageLabelIfNeeded()
    }

    accessibilityLabel = accessibilityParts.joined(separator: ", ")
  }

  private func ensureTitleLabel() -> UILabel {
    if let titleLabel {
      return titleLabel
    }
    let label = makeLabel()
    titleLabel = label
    return label
  }

  private func ensureMessageLabel() -> UILabel {
    if let messageLabel {
      return messageLabel
    }
    let label = makeLabel()
    messageLabel = label
    return label
  }

  private func makeLabel() -> UILabel {
    let label = UILabel()
    label.textAlignment = .center
    label.numberOfLines = 0
    return label
  }

  private func removeTitleLabelIfNeeded() {
    guard let titleLabel else { return }
    stack.removeArrangedSubview(titleLabel)
    titleLabel.removeFromSuperview()
    titleLabel.text = nil
    self.titleLabel = nil
  }

  private func removeMessageLabelIfNeeded() {
    guard let messageLabel else { return }
    stack.removeArrangedSubview(messageLabel)
    messageLabel.removeFromSuperview()
    messageLabel.text = nil
    self.messageLabel = nil
  }
}
