import FKCoreKit
import UIKit

/// Social activity feed row with avatar, action text, and quoted preview (D-49).
@MainActor
public final class FKCellActivityCell: UITableViewCell, FKCellReusable {
  public typealias ViewModel = FKCellActivityRow

  private let groupedBackground = FKCellGroupedBackgroundView()
  private let rootStack = UIStackView()
  private let avatarSlot = FKCellAvatarSlotView()
  private let textColumn = UIStackView()
  private let activityLabel = UILabel()
  private let quoteLabel = UILabel()
  private let timestampLabel = UILabel()
  private let separator = FKCellSeparatorLayout.makeDivider()

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    commonInit()
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
    commonInit()
  }

  public func apply(_ configuration: FKCellActivityConfiguration) {
    apply(configuration, appearance: .default, imageURL: nil, image: nil)
  }

  public func apply(
    _ configuration: FKCellActivityConfiguration,
    appearance: FKCellAppearanceConfiguration = .default,
    imageURL: URL? = nil,
    image: UIImage? = nil
  ) {
    avatarSlot.apply(
      configuration: configuration.avatarConfiguration,
      displayName: configuration.actorName,
      imageURL: imageURL,
      image: image
    )
    activityLabel.text = "\(configuration.actorName) \(configuration.actionText)"
    if let preview = configuration.targetPreview, !preview.isEmpty {
      quoteLabel.text = preview
      quoteLabel.isHidden = false
    } else {
      quoteLabel.isHidden = true
    }
    if let ts = configuration.timestamp {
      timestampLabel.text = ts
      timestampLabel.isHidden = false
    } else {
      timestampLabel.isHidden = true
    }

    groupedBackground.apply(nil)
    FKCellSeparatorLayout.updateVisibility(
      divider: separator,
      policy: configuration.separatorPolicy,
      isLastInSection: configuration.isLastInSection
    )
    backgroundColor = appearance.cellBackgroundColor
    contentView.backgroundColor = appearance.cellBackgroundColor
    isUserInteractionEnabled = configuration.isEnabled
    alpha = configuration.isEnabled ? 1 : 0.5
    selectionStyle = configuration.isEnabled ? .default : .none
    accessibilityLabel = activityLabel.text
  }

  public func configure(with viewModel: FKCellActivityRow) {
    apply(viewModel.configuration, imageURL: viewModel.imageURL, image: viewModel.image)
  }

  public override func prepareForReuse() {
    super.prepareForReuse()
    avatarSlot.resetForReuse()
    activityLabel.text = nil
    quoteLabel.text = nil
    quoteLabel.isHidden = true
    timestampLabel.text = nil
    timestampLabel.isHidden = true
    selectionStyle = .default
    accessibilityLabel = nil
  }

  private func commonInit() {
    backgroundColor = .clear
    contentView.backgroundColor = .clear
    groupedBackground.translatesAutoresizingMaskIntoConstraints = false
    rootStack.axis = .horizontal
    rootStack.alignment = .top
    rootStack.spacing = FKCellLayoutMetrics.iconColumnSpacing
    rootStack.translatesAutoresizingMaskIntoConstraints = false

    textColumn.axis = .vertical
    textColumn.spacing = 4

    activityLabel.font = .preferredFont(forTextStyle: .body)
    activityLabel.numberOfLines = 2
    activityLabel.adjustsFontForContentSizeCategory = true

    quoteLabel.font = .preferredFont(forTextStyle: .subheadline)
    quoteLabel.textColor = .secondaryLabel
    quoteLabel.numberOfLines = 2
    quoteLabel.adjustsFontForContentSizeCategory = true

    timestampLabel.font = .preferredFont(forTextStyle: .caption1)
    timestampLabel.textColor = .tertiaryLabel
    timestampLabel.isHidden = true

    textColumn.addArrangedSubview(activityLabel)
    textColumn.addArrangedSubview(quoteLabel)
    textColumn.addArrangedSubview(timestampLabel)

    rootStack.addArrangedSubview(avatarSlot)
    rootStack.addArrangedSubview(textColumn)

    separator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(groupedBackground)
    contentView.addSubview(rootStack)
    contentView.addSubview(separator)

    let insets = FKCellAppearanceConfiguration.default.contentInsets
    NSLayoutConstraint.activate([
      groupedBackground.topAnchor.constraint(equalTo: contentView.topAnchor),
      groupedBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
      groupedBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      groupedBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

      rootStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: insets.top),
      rootStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: insets.left),
      rootStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -insets.right),
      rootStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -insets.bottom),

      avatarSlot.widthAnchor.constraint(equalToConstant: FKCellLayoutMetrics.feedAvatarSize),
      avatarSlot.heightAnchor.constraint(equalToConstant: FKCellLayoutMetrics.feedAvatarSize),

      separator.leadingAnchor.constraint(equalTo: activityLabel.leadingAnchor),
      separator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
      separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
    ])
  }
}
