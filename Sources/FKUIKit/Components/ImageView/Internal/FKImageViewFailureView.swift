import UIKit

/// Failure overlay with optional retry affordance.
@MainActor
final class FKImageViewFailureView: UIView {
  var onRetry: (() -> Void)?

  private let stack = UIStackView()
  private let iconView = UIImageView()
  private let messageLabel = UILabel()
  private let retryButton = FKButton()
  private var allowsTapToRetry = false

  override init(frame: CGRect) {
    super.init(frame: frame)
    isHidden = true
    backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.92)

    stack.axis = .vertical
    stack.alignment = .center
    stack.spacing = 8
    stack.translatesAutoresizingMaskIntoConstraints = false
    stack.isUserInteractionEnabled = true

    iconView.contentMode = .scaleAspectFit
    iconView.tintColor = .secondaryLabel
    iconView.setContentHuggingPriority(.required, for: .vertical)

    messageLabel.textAlignment = .center
    messageLabel.numberOfLines = 0
    messageLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
    messageLabel.textColor = .secondaryLabel
    messageLabel.adjustsFontForContentSizeCategory = true

    retryButton.isHidden = true
    retryButton.addAction(UIAction { [weak self] _ in
      self?.onRetry?()
    }, for: .primaryActionTriggered)

    stack.addArrangedSubview(iconView)
    stack.addArrangedSubview(messageLabel)
    stack.addArrangedSubview(retryButton)
    addSubview(stack)

    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 12),
      stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
      stack.centerXAnchor.constraint(equalTo: centerXAnchor),
      stack.centerYAnchor.constraint(equalTo: centerYAnchor),
      iconView.widthAnchor.constraint(equalToConstant: 32),
      iconView.heightAnchor.constraint(equalToConstant: 32),
    ])

    let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    addGestureRecognizer(tap)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func apply(
    configuration: FKImageViewFailureConfiguration,
    reason: FKImageViewFailureReason
  ) {
    let icon = configuration.iconImage
      ?? UIImage(systemName: configuration.iconSymbolName)
    iconView.image = icon?.withRenderingMode(.alwaysTemplate)

    let message = configuration.resolvedMessage(for: reason)
    messageLabel.text = message
    messageLabel.isHidden = message == nil

    let showsButton = configuration.isRetryEnabled && configuration.retryButtonTitle != nil
    allowsTapToRetry = configuration.isRetryEnabled && configuration.retryButtonTitle == nil
    retryButton.isHidden = !showsButton
    if showsButton {
      retryButton.setTitle(
        FKButton.LabelAttributes(text: configuration.resolvedRetryTitle),
        for: .normal
      )
    }
    isUserInteractionEnabled = configuration.isRetryEnabled
  }

  @objc private func handleTap() {
    guard allowsTapToRetry else { return }
    onRetry?()
  }
}
