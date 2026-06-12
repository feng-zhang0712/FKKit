import UIKit

/// Shared conversation row content for table and collection cells (D-20).
@MainActor
final class FKCellConversationContentView: UIView {
  let groupedBackground = FKCellGroupedBackgroundView()
  private let rootStack = UIStackView()
  let avatarSlot = FKCellAvatarSlotView()
  private let textColumn = UIStackView()
  let titleLabel = UILabel()
  let previewLabel = UILabel()
  let metaColumn = FKCellFeedMetaColumnView()
  private let separator = FKCellSeparatorLayout.makeDivider()

  override init(frame: CGRect) {
    super.init(frame: frame)
    commonInit()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  func apply(
    configuration: FKCellConversationConfiguration,
    appearance: FKCellAppearanceConfiguration,
    imageURL: URL?,
    image: UIImage?,
    host: FKCellChromeHost
  ) {
    avatarSlot.apply(
      configuration: configuration.avatarConfiguration,
      displayName: configuration.title,
      imageURL: imageURL,
      image: image
    )
    titleLabel.text = configuration.title
    previewLabel.text = configuration.preview
    previewLabel.isHidden = configuration.preview?.isEmpty ?? true
    previewLabel.textColor = appearance.secondaryLabelColor

    metaColumn.apply(timestamp: configuration.timestamp, unread: configuration.unread)
    FKCellUnreadApplicator.apply(
      presentation: configuration.unread,
      to: host,
      titleLabel: titleLabel,
      appearance: appearance
    )

    groupedBackground.apply(nil)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )

    host.backgroundColor = appearance.cellBackgroundColor
    if let tint = configuration.unread.backgroundTint, configuration.unread.isUnread {
      host.contentView.backgroundColor = tint
    } else {
      host.contentView.backgroundColor = appearance.cellBackgroundColor
    }

    host.isUserInteractionEnabled = configuration.isEnabled
    host.alpha = configuration.isEnabled ? 1 : 0.5
  }

  func resetForReuse() {
    avatarSlot.resetForReuse()
    metaColumn.reset()
    titleLabel.text = nil
    previewLabel.text = nil
    previewLabel.isHidden = true
  }

  private func commonInit() {
    backgroundColor = .clear
    groupedBackground.translatesAutoresizingMaskIntoConstraints = false
    rootStack.axis = .horizontal
    rootStack.alignment = .center
    rootStack.spacing = FKCellLayoutMetrics.iconColumnSpacing
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    textColumn.axis = .vertical
    textColumn.spacing = FKCellLayoutMetrics.titleSubtitleSpacing
    textColumn.setContentHuggingPriority(.defaultLow, for: .horizontal)

    titleLabel.font = .preferredFont(forTextStyle: .body)
    titleLabel.adjustsFontForContentSizeCategory = true
    titleLabel.numberOfLines = 1

    previewLabel.font = .preferredFont(forTextStyle: .subheadline)
    previewLabel.textColor = .secondaryLabel
    previewLabel.adjustsFontForContentSizeCategory = true
    previewLabel.numberOfLines = 2

    textColumn.addArrangedSubview(titleLabel)
    textColumn.addArrangedSubview(previewLabel)

    rootStack.addArrangedSubview(avatarSlot)
    rootStack.addArrangedSubview(textColumn)
    rootStack.addArrangedSubview(metaColumn)

    separator.translatesAutoresizingMaskIntoConstraints = false

    addSubview(groupedBackground)
    addSubview(rootStack)
    addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      groupedBackground.topAnchor.constraint(equalTo: topAnchor),
      groupedBackground.leadingAnchor.constraint(equalTo: leadingAnchor),
      groupedBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
      groupedBackground.bottomAnchor.constraint(equalTo: bottomAnchor),

      rootStack.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
      rootStack.heightAnchor.constraint(greaterThanOrEqualToConstant: FKCellLayoutMetrics.doubleLineRowHeight),

      avatarSlot.widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.feedAvatarSize),
      avatarSlot.heightAnchor.constraint(equalToConstant: FKCellLayoutMetrics.feedAvatarSize),

      separator.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }
}
