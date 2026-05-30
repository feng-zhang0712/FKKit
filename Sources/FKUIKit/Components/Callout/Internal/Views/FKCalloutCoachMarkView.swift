import UIKit

@MainActor
final class FKCalloutCoachMarkView: UIView {
  var onPrimaryAction: (() -> Void)?
  var onClose: (() -> Void)?

  init(content: FKCalloutCoachMarkContent, configuration: FKCalloutConfiguration) {
    super.init(frame: .zero)
    build(content: content, configuration: configuration)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    nil
  }

  /// Intrinsic content size inside the bubble content container (excludes bubble `contentInsets` and beak padding).
  static func preferredSize(content: FKCalloutCoachMarkContent, configuration: FKCalloutConfiguration, maxWidth: CGFloat) -> CGSize {
    let closeButtonWidth: CGFloat = content.showsCloseButton ? 28 : 0
    let headerSpacing: CGFloat = content.showsCloseButton ? 8 : 0
    let titleRowLimit = max(1, maxWidth - closeButtonWidth - headerSpacing)
    let titleHeight = textHeight(content.title, font: configuration.titleFont, width: titleRowLimit)
    let bodyHeight = textHeight(content.message, font: configuration.font, width: maxWidth)
    let titleRowWidth = measuredWidth(content.title, configuration.titleFont, limit: titleRowLimit) + headerSpacing + closeButtonWidth
    let bodyWidth = measuredWidth(content.message, configuration.font, limit: maxWidth)
    let primaryWidth = measuredPrimaryActionWidth(content.primaryActionTitle)
    let width = min(maxWidth, max(titleRowWidth, bodyWidth, primaryWidth))
    let buttonHeight = measuredPrimaryActionHeight(content.primaryActionTitle)
    let height = titleHeight + 8 + bodyHeight + 16 + buttonHeight + layoutBottomClearance
    return CGSize(width: ceil(width), height: ceil(height))
  }

  /// Extra clearance so capsule buttons are not clipped by the bubble chrome.
  private static let layoutBottomClearance: CGFloat = 6

  private func build(content: FKCalloutCoachMarkContent, configuration: FKCalloutConfiguration) {
    let titleLabel = UILabel()
    titleLabel.font = configuration.titleFont
    titleLabel.textColor = configuration.appearance.resolvedTextColor(traitCollection: traitCollection)
    titleLabel.numberOfLines = 0
    titleLabel.text = content.title

    let closeButton = UIButton(type: .system)
    closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
    closeButton.tintColor = .secondaryLabel
    closeButton.isHidden = !content.showsCloseButton
    closeButton.addAction(UIAction { [weak self] _ in self?.onClose?() }, for: .touchUpInside)

    let messageLabel = UILabel()
    messageLabel.font = configuration.font
    messageLabel.textColor = configuration.appearance.resolvedSecondaryTextColor(traitCollection: traitCollection)
    messageLabel.numberOfLines = 0
    messageLabel.text = content.message

    let primaryButton = UIButton(type: .system)
    var buttonConfig = UIButton.Configuration.filled()
    buttonConfig.title = content.primaryActionTitle
    buttonConfig.baseBackgroundColor = .label
    buttonConfig.baseForegroundColor = .systemBackground
    buttonConfig.cornerStyle = .capsule
    buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    primaryButton.configuration = buttonConfig
    primaryButton.addAction(UIAction { [weak self] _ in self?.onPrimaryAction?() }, for: .touchUpInside)

    let headerRow = UIStackView(arrangedSubviews: [titleLabel, closeButton])
    headerRow.axis = .horizontal
    headerRow.alignment = .top
    headerRow.spacing = 8
    headerRow.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    closeButton.setContentHuggingPriority(.required, for: .horizontal)
    closeButton.setContentCompressionResistancePriority(.required, for: .horizontal)

    [headerRow, messageLabel, primaryButton].forEach {
      $0.translatesAutoresizingMaskIntoConstraints = false
      addSubview($0)
    }

    NSLayoutConstraint.activate([
      closeButton.widthAnchor.constraint(equalToConstant: 28),
      closeButton.heightAnchor.constraint(equalToConstant: 28),

      headerRow.topAnchor.constraint(equalTo: topAnchor),
      headerRow.leadingAnchor.constraint(equalTo: leadingAnchor),
      headerRow.trailingAnchor.constraint(equalTo: trailingAnchor),

      messageLabel.topAnchor.constraint(equalTo: headerRow.bottomAnchor, constant: 8),
      messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
      messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

      primaryButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
      primaryButton.leadingAnchor.constraint(equalTo: leadingAnchor),
      bottomAnchor.constraint(equalTo: primaryButton.bottomAnchor),
    ])
  }

  private static func textHeight(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
    let label = UILabel()
    label.font = font
    label.text = text
    label.numberOfLines = 0
    return label.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
  }

  private static func measuredWidth(_ text: String, _ font: UIFont, limit: CGFloat) -> CGFloat {
    ceil((text as NSString).boundingRect(
      with: CGSize(width: limit, height: .greatestFiniteMagnitude),
      options: [.usesLineFragmentOrigin, .usesFontLeading],
      attributes: [.font: font],
      context: nil
    ).width)
  }

  private static func measuredPrimaryActionWidth(_ title: String) -> CGFloat {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .capsule
    config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    let button = UIButton(configuration: config)
    return button.intrinsicContentSize.width
  }

  private static func measuredPrimaryActionHeight(_ title: String) -> CGFloat {
    var config = UIButton.Configuration.filled()
    config.title = title
    config.cornerStyle = .capsule
    config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
    let button = UIButton(configuration: config)
    return button.intrinsicContentSize.height
  }
}
